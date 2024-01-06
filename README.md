[![Ruby on Rails CI](https://github.com/Embloy/Embloy-Core-Server/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/Embloy/Embloy-Core-Server/actions/workflows/rubyonrails.yml) ![Codecov](https://img.shields.io/codecov/c/github/embloy/embloy-core-server)

<h1><a href="https://embloy.com">Embloy</a></h1>

> __NOTE__: _The current prototype deployed at ***[beta.embloy.com](beta.embloy.com)*** can take up to 60
seconds to load due to render's server instance having to boot up after being inactive for a while._

> __NOTE__: _If you're interested in finding out more or if you want to integrate Embloy into your system,
check out the developer documentation at ***[developer.embloy.com](developer.embloy.com)***._

This repository contains the backend code for our application and API, excluding the web-application client. We
have recently deployed an initial prototype at ***[beta.embloy.com](beta.embloy.com)***, although it is not yet 
publicly accessible (you can already create an account, but to proceed we, need to authorize you first). If
you are interested and would like to take a look, please reach out to us at
___[info@embloy.com](mailto:info@embloy.com?subject=I%20want%20to%20have%20a%20look%20at%20your%20prototype!)___

## License

### Licensed under

> GNU AFFERO GENERAL PUBLIC LICENSE v3.0 ([gpl-3](https://www.gnu.org/licenses/gpl-3.0.en.html))

## Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by anyone, as
defined in the GNU AFFERO GENERAL PUBLIC LICENSE v3.0 license, shall be licensed as above, without any additional terms
or conditions.

## Functionality

> __NOTE__: _This file covers the general functionality of the Embloy-Core-Server. If you are looking for the API documentation instead, go to_
___[our Postman collection](https://postman.com/embloy)___

### User Authentication

Users can set up an account with their email address and password, or choose to log in using the OAuth2.0 services
provided by Google and GitHub. Once an account is created, it needs to be verified by clicking on the email.

Passwords are instantly hashed using [bcryt](https://en.wikipedia.org/wiki/Bcrypt) and stored in the database as a
hash. In case a user forgets their password, it can be reset via standard email authentication.

For an optimal user experience, it is recommended to fill out the 'Preferences' field under 'My Profile'.
To log into the application, users can use the aforementioned OAuth2.0 services or enter their password.
If a user forgets their password, they can reset it by providing their email address and following the specified
procedure in the email.

### Subscriptions

Embloy partners with Stripe for simplified billing. Most Embloy services can be used for free, but for verification, the user needs to be subscribed to one of the following:

- Embloy-Basic: 0 EUR
- Embloy-Smart: xx EUR
- Embloy-Genius xx EUR

Subscriptions are per default on a monthly basis, but can be customized to be dependent on API use. For more information, see the [subscription documentation](https://developer.embloy.com/docs/category/subscriptions). 

### Quicklink

With Quicklink you can integrate Embloy into your web service. What PayPal is for transactions, Embloy-Quicklink is for applications. We designed Quicklink to be as easy to use as possible, requiring minimal effort to be integrated on your job posting site. All you have to do is add the "Apply with EMBLOY" button to your client and add one Endpoint to your server and the rest is managed by Embloy.
For more information, see the [Quicklink documentation](https://developer.embloy.com/docs/category/quicklink). 

### Genius-Queries

Embedding Embloy content on external platforms made ease. Create a new Genius-Query and upload it to your social media platform to direct new applicants directly to your Embloy job application. For more information, see the [Genius-Queries documentation](https://developer.embloy.com/docs/category/genius). 

### Job Posting

Authenticated users can create new job listings/postings (including a fitting title, a short description, a high-resolution cover image and more) and, depending on the employer's liking, also define customized CV and motivation
letter requirements.
This customization includes specifying whether a CV or a motivation letter is required for the application, and if
required, employers can also indicate their preferred file formats to ensure that the applications meet the employer's
expectations.

Other users can then view these job listings and apply for the positions.

### Managing Applications for Available Jobs

The system is capable of managing jobs and applications, supporting
basic [CRUD operations](https://www.javatpoint.com/crud-operations-in-sql), and notifying the employer when a new
application is submitted, as well as notifying the applicant when their application is accepted or rejected.

All notifications are sent via [SMTP](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol).
Uploaded images are stored and encrypted on a Backblaze B2 Bucket (soon to be migrated to AWS S3).

### Filtering of Available Jobs and Creating an "Intelligent" Feed

***The FeedGenerator has been migrated to an external system after mutual agreement among the developers. Although the
details of the project are confidential, a basic understanding of its functionality is necessary to work on the Rails
backend. The enhanced FeedGenerator features a single REST API endpoint, which can only be accessed by the Rails server
via an authentication barrier. Credentials are provided on a need-to-know basis. The FeedGenerator ranks each element of
a set of jobs (or "slice") that are provided by the Rails backend. The resulting feed is then displayed to the user.***

The job feed delivers personalized job recommendations based on the user's preferences and behavior.
The user can also utilize our advanced search functionality, which includes comprehensive filtering and sorting options
for direct job exploration.

Additionally, our interactive map interface, powered by the [OpenStreetMap API](https://www.openstreetmap.org), provides
a visual overview of job opportunities.

## How it Works

To get started, simply visit [our website](http://embloy.com/) and create a new account or log in with an existing
account. It's that easy!

## Running on Docker

Go into the project directory and run: \
`$ docker build -t embloy .`\
`$ docker run -it -p 3000:3000 embloy `

To deploy to docker-hub: \
`$ docker tag embloy:latest <docker-username>/<docker-repository>`\
`$ docker push <docker-username>/<docker-repository>`

## Config

> __NOTE__: _You only need to follow these steps if you wish to contribute and need to test your changes locally_

<details>
  <summary> 1. Prerequisites </summary>

- Install Ruby 3.2.2

- Install Rails 7

- Install Postgresql 16

- Open pgAdmin4

- Add a new server

</details>

<details>
  <summary> 2. Connect to our remote database </summary>

-     hostname/address: <>

-     maintanence database: <>

-     username: <>

-     password: <>

-     port: 5432

</details>

<details>
  <summary> 3. Start the server </summary>

If you wish to experiment on our backend or contribute to our front end, you can test your changes by starting a local
server.

1. Create a file 'config/env_var.rb' with the following content:

   ```Ruby
   ENV['RAILS_MASTER_KEY'] = <>
   ENV['RAILS_SERVE_STATIC_FILES'] = <>
   ENV['SERVICE_HOST'] = <>
   # DATABASE ACCESS
   ENV['DATABASE_HOST'] = <>
   ENV['DATABASE_PASSWORD'] = <>
   ENV['DATABASE_URL'] = <>
   ENV['DATABASE_URL'] = <>
   ENV['DATABASE_USER'] = <>
   ENV['MONGO_DATABASE_URI'] = <>
   # OAUTH2 CODES
   ## GOOGLE
   ENV['GOOGLE_OAUTH2_KEY'] = <>
   ENV['GOOGLE_OAUTH2_SECRET'] = <>
   ## GITHUB: embloy.onrender
   ENV['GITHUB_KEY'] = <>
   ENV['GITHUB_SECRET'] = <>
   # E-MAIL CREDENTIALS
   ENV['EMAIL_ADDRESS'] = <>
   ENV['EMAIL_HOST'] = <>
   ENV['EMAIL_INFO_USER'] = <>
   ENV['EMAIL_NOREPLY_USER'] = <>
   ENV['EMAIL_PASSWORD'] = <>
   # TOKEN SECRETS
   ENV['REFRESH_TOKEN_SECRET'] = <>
   ENV['ACCESS_TOKEN_SECRET'] = <>
   ENV['CLIENT_TOKEN_SECRET'] = <>
   ENV['REQUEST_TOKEN_SECRET'] = <>
   # CORS CLIENT_URL
   ENV['CORS_CLIENT_URL'] = <>
   ENV['CORS_GENIUS_CLIENT_URL'] = <>
   # BACKBLAZE B2 BUCKET
   ENV['BUCKET_APPLICATION_KEY_ID'] = <>
   ENV['BUCKET_APPLICATION_KEY'] = <>
   ENV['BUCKET_NAME'] = <>
   ENV['BUCKET_ID'] = <>
   ENV['BUCKET_REGION'] = <>
   ENV['BUCKET_ENDPOINT'] = <>
   # STRIPE
   ENV['STRIPE_PUBLISHABLE_KEY'] = <>
   ENV['STRIPE_SECRET_KEY'] = <>
   ENV['STRIPE_SIGNING_SECRET'] = <>
   ENV['STRIPE_WEBHOOK_SECRET'] = <>
   # FG
   ENV['ADMIN_PW'] = <>
   ENV['ADMIN_U'] = <>
   ```

1. Run ``$ rails db:create`` to create all necessary tables in your development database.
2. Run ``$ rails db:migrate`` to migrate your changes to the database.
3. Run ``$ rails server`` to start the server.
4. Add the following lines manually when resetting the current database or creating a new database:

   ```SQL
   CREATE EXTENSION postgis;
   ALTER TABLE jobs ADD COLUMN job_value public.geography(PointZ,4326);
   CREATE INDEX IF NOT EXISTS job_job_value_index
   ON public.jobs USING gist
   (job_value)
   TABLESPACE pg_default;
   ```

</details>

4. Go to http://localhost:3000

5. To enable subscriptions and Embloy Quicklink, make sure to have StripeCLI installed and have an active webhook:

```Bash
./stripe listen --forward-to localhost:3000/pay/webhooks/stripe
```

## What's next

> __NOTE__: _See [GitHub issues](https://github.com/embloy/embloy-backend/issues) for more information_

---

© Carlo Bortolan, Jan Hummel

> Carlo Bortolan &nbsp;&middot;&nbsp;
> GitHub [@carlobortolan](https://github.com/carlobortolan) &nbsp;&middot;&nbsp;
> contact via [bortolanoffice@embloy.com](mailto:bortolanoffice@embloy.com)
>
> Jan Hummel &nbsp;&middot;&nbsp;
> GitHub [@github4touchdouble](https://github.com/github4touchdouble) &nbsp;&middot;&nbsp;
> contact via [hummeloffice@embloy.com](mailto:hummeloffice@embloy.com)
