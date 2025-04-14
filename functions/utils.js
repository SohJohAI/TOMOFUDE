/**
 * Generates a unique referral code.
 * 
 * @param {FirebaseFirestore.Firestore} db - Firestore database instance
 * @param {number} length - Length of the referral code (default: 8)
 * @param {number} maxAttempts - Maximum number of attempts to generate a unique code (default: 10)
 * @returns {Promise<string>} A unique referral code
 */
exports.generateUniqueReferralCode = async (db, length = 8, maxAttempts = 10) => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let attempts = 0;

    while (attempts < maxAttempts) {
        // Generate a random code
        let code = '';
        for (let i = 0; i < length; i++) {
            code += chars.charAt(Math.floor(Math.random() * chars.length));
        }

        // Check if the code already exists
        const codeDoc = await db.collection('referralCodes').doc(code).get();

        if (!codeDoc.exists) {
            return code;
        }

        attempts++;
    }

    // If we've reached the maximum number of attempts, use a timestamp-based code
    const timestamp = Date.now().toString(36).toUpperCase();
    const randomChars = Array(length - timestamp.length)
        .fill()
        .map(() => chars.charAt(Math.floor(Math.random() * chars.length)))
        .join('');

    return (randomChars + timestamp).slice(0, length);
};

/**
 * Validates a referral code format.
 * 
 * @param {string} code - The referral code to validate
 * @returns {boolean} True if the code is valid, false otherwise
 */
exports.validateReferralCode = (code) => {
    if (!code || typeof code !== 'string') {
        return false;
    }

    // Check if the code is 8 characters long and contains only uppercase letters and numbers
    return /^[A-Z0-9]{8}$/.test(code);
};

/**
 * Calculates the expiry date for points or referral codes.
 * 
 * @param {number} months - Number of months from now (default: 3)
 * @returns {Date} The expiry date
 */
exports.calculateExpiryDate = (months = 3) => {
    const expiryDate = new Date();
    expiryDate.setMonth(expiryDate.getMonth() + months);
    return expiryDate;
};

/**
 * Checks if a date is expired.
 * 
 * @param {Date} date - The date to check
 * @returns {boolean} True if the date is expired, false otherwise
 */
exports.isExpired = (date) => {
    if (!date) {
        return false;
    }

    return date < new Date();
};

/**
 * Formats a date to a human-readable string.
 * 
 * @param {Date} date - The date to format
 * @param {string} locale - The locale to use (default: 'ja-JP')
 * @returns {string} The formatted date string
 */
exports.formatDate = (date, locale = 'ja-JP') => {
    if (!date) {
        return '';
    }

    return date.toLocaleDateString(locale, {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
    });
};

/**
 * Formats a point amount with a sign and unit.
 * 
 * @param {number} amount - The point amount
 * @returns {string} The formatted point amount
 */
exports.formatPoints = (amount) => {
    if (amount >= 0) {
        return `+${amount} P`;
    } else {
        return `${amount} P`;
    }
};
