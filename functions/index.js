const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { generateUniqueReferralCode } = require('./utils');

// Initialize Firebase Admin
admin.initializeApp();

// Firestore reference
const db = admin.firestore();

/**
 * Triggered when a new user is created in Firebase Auth.
 * Creates a new user document in Firestore with initial points and a referral code.
 */
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
    const uid = user.uid;
    const now = admin.firestore.Timestamp.now();

    // Calculate expiry date (3 months from now)
    const expiryDate = new Date();
    expiryDate.setMonth(expiryDate.getMonth() + 3);

    try {
        // Generate a unique referral code
        const referralCode = await generateUniqueReferralCode(db);

        // Run transaction to ensure data consistency
        return db.runTransaction(async (transaction) => {
            // Create user document
            const userRef = db.collection('users').doc(uid);
            transaction.set(userRef, {
                uid,
                email: user.email || '',
                displayName: user.displayName || '',
                point: 1000,
                freePoint: 1000,
                paidPoint: 0,
                referralCode,
                referredBy: null,
                createdAt: now,
                lastResetDate: now,
                referralCount: 0,
                referralExpiry: admin.firestore.Timestamp.fromDate(expiryDate)
            });

            // Create referral code document for reverse lookup
            const codeRef = db.collection('referralCodes').doc(referralCode);
            transaction.set(codeRef, {
                code: referralCode,
                userId: uid,
                createdAt: now,
                expiryDate: admin.firestore.Timestamp.fromDate(expiryDate),
                isActive: true
            });

            // Add history record for initial bonus
            const historyRef = userRef.collection('history').doc();
            transaction.set(historyRef, {
                id: historyRef.id,
                userId: uid,
                type: 'register_bonus',
                amount: 1000,
                timestamp: now,
                description: '初回登録ボーナス',
                expiryDate: admin.firestore.Timestamp.fromDate(expiryDate)
            });

            console.log(`User ${uid} created with referral code ${referralCode}`);
        });
    } catch (error) {
        console.error('Error creating user document:', error);
        throw error;
    }
});

/**
 * Apply a referral code to get bonus points.
 * The referrer gets 1500 points, and the referred user gets 500 points.
 */
exports.applyReferralBonus = functions.https.onCall(async (data, context) => {
    // Check if the user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated to apply a referral code'
        );
    }

    const userId = context.auth.uid;
    const { referralCode } = data;

    // Validate referral code format
    if (!referralCode || typeof referralCode !== 'string' || !/^[A-Z0-9]{8}$/.test(referralCode)) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid referral code format'
        );
    }

    try {
        return db.runTransaction(async (transaction) => {
            // Get user document
            const userRef = db.collection('users').doc(userId);
            const userDoc = await transaction.get(userRef);

            if (!userDoc.exists) {
                throw new functions.https.HttpsError(
                    'not-found',
                    'User not found'
                );
            }

            const userData = userDoc.data();

            // Check if user has already used a referral code
            if (userData.referredBy) {
                throw new functions.https.HttpsError(
                    'already-exists',
                    'User has already used a referral code'
                );
            }

            // Get referral code document
            const codeRef = db.collection('referralCodes').doc(referralCode);
            const codeDoc = await transaction.get(codeRef);

            if (!codeDoc.exists) {
                throw new functions.https.HttpsError(
                    'not-found',
                    'Invalid referral code'
                );
            }

            const codeData = codeDoc.data();

            // Check if code is active
            if (!codeData.isActive) {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    'Referral code is inactive'
                );
            }

            // Check if code has expired
            if (codeData.expiryDate.toDate() < new Date()) {
                throw new functions.https.HttpsError(
                    'failed-precondition',
                    'Referral code has expired'
                );
            }

            // Check if user is trying to use their own code
            if (codeData.userId === userId) {
                throw new functions.https.HttpsError(
                    'invalid-argument',
                    'Cannot use your own referral code'
                );
            }

            // Get referrer document
            const referrerRef = db.collection('users').doc(codeData.userId);
            const referrerDoc = await transaction.get(referrerRef);

            if (!referrerDoc.exists) {
                throw new functions.https.HttpsError(
                    'not-found',
                    'Referrer not found'
                );
            }

            const referrerData = referrerDoc.data();
            const now = admin.firestore.Timestamp.now();

            // Calculate expiry date (3 months from now)
            const expiryDate = new Date();
            expiryDate.setMonth(expiryDate.getMonth() + 3);

            // Update referred user (new user)
            const newUserBonus = 500;
            transaction.update(userRef, {
                point: userData.point + newUserBonus,
                freePoint: userData.freePoint + newUserBonus,
                referredBy: referralCode
            });

            // Add history record for referred user
            const userHistoryRef = userRef.collection('history').doc();
            transaction.set(userHistoryRef, {
                id: userHistoryRef.id,
                userId,
                type: 'referral_used',
                amount: newUserBonus,
                timestamp: now,
                description: '紹介コード利用ボーナス',
                expiryDate: admin.firestore.Timestamp.fromDate(expiryDate)
            });

            // Update referrer
            const referrerBonus = 1500;
            transaction.update(referrerRef, {
                point: referrerData.point + referrerBonus,
                freePoint: referrerData.freePoint + referrerBonus,
                referralCount: referrerData.referralCount + 1
            });

            // Add history record for referrer
            const referrerHistoryRef = referrerRef.collection('history').doc();
            transaction.set(referrerHistoryRef, {
                id: referrerHistoryRef.id,
                userId: codeData.userId,
                type: 'referral_bonus',
                amount: referrerBonus,
                timestamp: now,
                description: '紹介ボーナス',
                expiryDate: admin.firestore.Timestamp.fromDate(expiryDate)
            });

            console.log(`Referral code ${referralCode} applied by user ${userId}`);

            return { success: true };
        });
    } catch (error) {
        console.error('Error applying referral code:', error);
        throw error;
    }
});

/**
 * Consume points for a specific purpose.
 * First consumes free points, then paid points if necessary.
 */
exports.consumePoints = functions.https.onCall(async (data, context) => {
    // Check if the user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated to consume points'
        );
    }

    const userId = context.auth.uid;
    const { amount, purpose } = data;

    // Validate amount
    if (!amount || typeof amount !== 'number' || amount <= 0) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Amount must be a positive number'
        );
    }

    try {
        return db.runTransaction(async (transaction) => {
            // Get user document
            const userRef = db.collection('users').doc(userId);
            const userDoc = await transaction.get(userRef);

            if (!userDoc.exists) {
                throw new functions.https.HttpsError(
                    'not-found',
                    'User not found'
                );
            }

            const userData = userDoc.data();

            // Check if user has enough points
            if (userData.point < amount) {
                throw new functions.https.HttpsError(
                    'resource-exhausted',
                    'Not enough points'
                );
            }

            // Calculate how many points to consume from free and paid
            let freePointsToUse = Math.min(userData.freePoint, amount);
            let paidPointsToUse = amount - freePointsToUse;

            // Update user document
            transaction.update(userRef, {
                point: userData.point - amount,
                freePoint: userData.freePoint - freePointsToUse,
                paidPoint: userData.paidPoint - paidPointsToUse
            });

            // Add history record
            const now = admin.firestore.Timestamp.now();
            const historyRef = userRef.collection('history').doc();
            transaction.set(historyRef, {
                id: historyRef.id,
                userId,
                type: 'point_consumption',
                amount: -amount,
                timestamp: now,
                description: purpose || 'ポイント消費',
                expiryDate: null  // Consumption records don't expire
            });

            console.log(`User ${userId} consumed ${amount} points (${freePointsToUse} free, ${paidPointsToUse} paid)`);

            return {
                success: true,
                freePointsUsed: freePointsToUse,
                paidPointsUsed: paidPointsToUse
            };
        });
    } catch (error) {
        console.error('Error consuming points:', error);
        throw error;
    }
});

/**
 * Get user's point information.
 */
exports.getUserPoint = functions.https.onCall(async (data, context) => {
    // Check if the user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated to get point information'
        );
    }

    const userId = context.auth.uid;

    try {
        // Get user document
        const userDoc = await db.collection('users').doc(userId).get();

        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                'not-found',
                'User not found'
            );
        }

        const userData = userDoc.data();

        return {
            point: userData.point,
            freePoint: userData.freePoint,
            paidPoint: userData.paidPoint,
            referralCode: userData.referralCode,
            referredBy: userData.referredBy,
            referralCount: userData.referralCount,
            lastResetDate: userData.lastResetDate.toDate()
        };
    } catch (error) {
        console.error('Error getting user point:', error);
        throw error;
    }
});

/**
 * Get user's point history.
 */
exports.getPointHistory = functions.https.onCall(async (data, context) => {
    // Check if the user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated to get point history'
        );
    }

    const userId = context.auth.uid;
    const limit = data?.limit || 50;  // Default to 50 records

    try {
        // Get history records
        const historySnapshot = await db.collection('users')
            .doc(userId)
            .collection('history')
            .orderBy('timestamp', 'desc')
            .limit(limit)
            .get();

        const history = historySnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                ...data,
                timestamp: data.timestamp.toDate(),
                expiryDate: data.expiryDate ? data.expiryDate.toDate() : null
            };
        });

        return { history };
    } catch (error) {
        console.error('Error getting point history:', error);
        throw error;
    }
});

/**
 * Reset free points at the beginning of each month.
 * Scheduled to run at 4:00 UTC on the 1st of each month.
 */
exports.resetMonthlyFreePoints = functions.pubsub
    .schedule('0 4 1 * *')
    .timeZone('UTC')
    .onRun(async (context) => {
        const now = admin.firestore.Timestamp.now();
        const batchSize = 500;  // Firestore batch limit

        // Calculate expiry date for history records (3 months from now)
        const expiryDate = new Date();
        expiryDate.setMonth(expiryDate.getMonth() + 3);

        try {
            // Process users in batches
            const processUsers = async (lastDocId = null) => {
                // Query users
                let query = db.collection('users');
                if (lastDocId) {
                    const lastDoc = await db.collection('users').doc(lastDocId).get();
                    query = query.startAfter(lastDoc);
                }
                query = query.limit(batchSize);

                const snapshot = await query.get();

                if (snapshot.empty) {
                    console.log('No more users to process');
                    return;
                }

                // Create a batch
                const batch = admin.batch();
                let lastId = null;

                // Process each user
                for (const doc of snapshot.docs) {
                    const userData = doc.data();
                    lastId = doc.id;

                    // Skip users with no free points
                    if (userData.freePoint <= 0) {
                        continue;
                    }

                    // Update user document
                    batch.update(doc.ref, {
                        point: userData.point - userData.freePoint,
                        freePoint: 0,
                        lastResetDate: now
                    });

                    // Add history record
                    const historyRef = doc.ref.collection('history').doc();
                    batch.set(historyRef, {
                        id: historyRef.id,
                        userId: doc.id,
                        type: 'monthly_reset',
                        amount: -userData.freePoint,
                        timestamp: now,
                        description: '月次無料ポイントリセット',
                        expiryDate: admin.firestore.Timestamp.fromDate(expiryDate)
                    });
                }

                // Commit the batch
                await batch.commit();
                console.log(`Processed ${snapshot.size} users`);

                // Process next batch if needed
                if (snapshot.size === batchSize) {
                    await processUsers(lastId);
                }
            };

            await processUsers();

            // Clean up expired history records
            const threeMonthsAgo = new Date();
            threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);
            const deleteBeforeDate = admin.firestore.Timestamp.fromDate(threeMonthsAgo);

            // This would need to be implemented as a separate function
            // due to the complexity of deleting subcollections across all users

            console.log('Monthly free points reset completed');
            return null;
        } catch (error) {
            console.error('Error resetting monthly free points:', error);
            throw error;
        }
    });
