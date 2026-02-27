# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

* Test commit for GH Actions v2

## Stripe Setup

1. **Create Products & Prices** in [Stripe Dashboard](https://dashboard.stripe.com/products):
   - **Growth**: $12/year recurring → copy the Price ID (starts with `price_`)
   - **Pro**: $9/month recurring → copy the Price ID

2. **Set environment variables**:
   ```bash
   STRIPE_PUBLISHABLE_KEY=pk_test_...
   STRIPE_SECRET_KEY=sk_test_...
   STRIPE_PRICE_GROWTH_ID=price_...
   STRIPE_PRICE_PRO_ID=price_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

3. **Configure webhook** in [Stripe Developers → Webhooks](https://dashboard.stripe.com/webhooks):
   - Endpoint: `https://your-domain.com/webhooks/stripe`
   - Events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`
   - Copy the signing secret to `STRIPE_WEBHOOK_SECRET`

4. **Local testing**: Use [Stripe CLI](https://stripe.com/docs/stripe-cli) to forward webhooks:
   ```bash
   stripe listen --forward-to localhost:3000/webhooks/stripe
   ```
