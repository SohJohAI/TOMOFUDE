import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@12.0.0'

// Initialize Stripe with the secret key from environment variables
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
    apiVersion: '2023-10-16',
})

// Initialize Supabase client with environment variables
const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
const supabase = createClient(supabaseUrl, supabaseKey)

// Define plan points mapping
const PLAN_POINTS = {
    'plan_ume': 500,   // 梅プラン: 500ポイント/月
    'plan_take': 1000, // 竹プラン: 1000ポイント/月
    'plan_matsu': 2000 // 松プラン: 2000ポイント/月
}

/**
 * Update user's plan and points in Supabase
 * @param userId The user's ID
 * @param planId The plan ID (e.g., 'plan_ume', 'plan_take', 'plan_matsu')
 */
const updateUserPlan = async (userId: string, planId: string) => {
    console.log(`Updating user ${userId} to plan ${planId}`)

    // Get points for the plan
    const points = PLAN_POINTS[planId as keyof typeof PLAN_POINTS] || 0

    try {
        // Get current user data
        const { data: userData, error: fetchError } = await supabase
            .from('users')
            .select('points')
            .eq('id', userId)
            .single()

        if (fetchError) {
            console.error('Error fetching user data:', fetchError)
            throw fetchError
        }

        // Calculate new points (keep existing points and add new plan points)
        const currentPoints = userData?.points || 0

        // Update user's plan and points
        const { data, error } = await supabase
            .from('users')
            .update({
                plan: planId,
                points: currentPoints + points
            })
            .eq('id', userId)

        if (error) {
            console.error('Error updating user plan:', error)
            throw error
        }

        // Add entry to point history
        const { error: historyError } = await supabase
            .from('point_history')
            .insert({
                user_id: userId,
                type: 'subscription',
                amount: points,
                description: `${planId} サブスクリプションポイント`,
            })

        if (historyError) {
            console.error('Error adding point history:', historyError)
            // Don't throw here, as the main update was successful
        }

        console.log(`Successfully updated user ${userId} to plan ${planId} with ${points} points`)
        return data
    } catch (err) {
        console.error('Error in updateUserPlan:', err)
        throw err
    }
}

// Handle HTTP requests
serve(async (req) => {
    // Get the signature from the headers
    const signature = req.headers.get('stripe-signature')

    if (!signature) {
        console.error('No Stripe signature found')
        return new Response(JSON.stringify({ error: 'No Stripe signature found' }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' }
        })
    }

    try {
        // Get the webhook secret from environment variables
        const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
        if (!webhookSecret) {
            throw new Error('STRIPE_WEBHOOK_SECRET is not set')
        }

        // Get the request body
        const body = await req.text()

        // Verify the event with Stripe
        const event = stripe.webhooks.constructEvent(
            body,
            signature,
            webhookSecret
        )

        console.log(`Received Stripe event: ${event.type}`)

        // Handle different event types
        switch (event.type) {
            case 'checkout.session.completed': {
                // Payment is successful and the subscription is created
                const session = event.data.object as Stripe.Checkout.Session

                // Get user ID and plan ID from metadata
                const userId = session.metadata?.userId
                const planId = session.metadata?.planId

                if (!userId || !planId) {
                    console.error('Missing userId or planId in session metadata')
                    break
                }

                // Update user's plan and points
                await updateUserPlan(userId, planId)
                break
            }

            case 'invoice.payment_succeeded': {
                // Recurring payment succeeded
                const invoice = event.data.object as Stripe.Invoice

                // Get subscription ID
                const subscriptionId = invoice.subscription as string
                if (!subscriptionId) {
                    console.error('No subscription ID found in invoice')
                    break
                }

                // Get subscription details
                const subscription = await stripe.subscriptions.retrieve(subscriptionId)

                // Get user ID and plan ID from metadata
                const userId = subscription.metadata?.userId
                const planId = subscription.metadata?.planId

                if (!userId || !planId) {
                    console.error('Missing userId or planId in subscription metadata')
                    break
                }

                // Update user's plan and points
                await updateUserPlan(userId, planId)
                break
            }

            case 'customer.subscription.deleted': {
                // Subscription was canceled
                const subscription = event.data.object as Stripe.Subscription

                // Get user ID from metadata
                const userId = subscription.metadata?.userId

                if (!userId) {
                    console.error('Missing userId in subscription metadata')
                    break
                }

                // Update user's plan to 'free'
                const { error } = await supabase
                    .from('users')
                    .update({ plan: 'free' })
                    .eq('id', userId)

                if (error) {
                    console.error('Error updating user plan to free:', error)
                } else {
                    console.log(`Successfully updated user ${userId} to free plan`)
                }
                break
            }
        }

        // Return a 200 response to acknowledge receipt of the event
        return new Response(JSON.stringify({ received: true }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        })
    } catch (err) {
        console.error(`Webhook error: ${err.message}`)
        return new Response(JSON.stringify({ error: err.message }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' }
        })
    }
})
