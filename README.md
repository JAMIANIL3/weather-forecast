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

## Environment variables (.env)

This project uses dotenv for local development. A non-secret example file is
provided at `.env.example`. Do NOT commit your personal `.env` file — the
repository ignores `.env` by default.

Quick setup:

1. Copy the example:

	```bash
	cp .env.example .env
	```

2. Fill in any secret values (for example, `OPENWEATHER_API_KEY`).

3. Start the app (development):

	```bash
	bundle install
	bin/rails server
	```

If you're using Docker or another deployment environment, set the equivalent
environment variables in your container/service configuration instead of
committing them to the repo.
