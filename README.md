[![Ruby on Rails CI](https://github.com/Embloy/Embloy-Core-Server/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/Embloy/Embloy-Core-Server/actions/workflows/rubyonrails.yml) ![Codecov](https://img.shields.io/codecov/c/github/embloy/embloy-core-server)

<h1><a href="https://embloy.com">Embloy Core Server</a></h1>

This repository contains the source code for our server-side applications and API.

> [!note]
> If you're interested in finding out more or if you want to integrate Embloy into your system, check out the
> developer documentation at **_[developers.embloy.com](developers.embloy.com)_** and API documentation at **_[docs.embloy.com](docs.embloy.com)_**.

## Services

| Service                  | Description                                         | Link                                                   | GitHub Repository                                                                                                            | Language                                                                                                                   |
| ------------------------ | --------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Core-Server**   | The main server application and API.                | [api.embloy.com](https://api.embloy.com)               | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-core-server)   | ![Ruby](https://img.shields.io/badge/Ruby-CC342D?logo=ruby&logoColor=white)                                               |
| **Proxy-Server**  | A simple proxy server for Embloy Quicklink.         | [apply.embloy.com](https://apply.embloy.com)           | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-core-server/proxy)  | ![Go](https://img.shields.io/badge/Go-00add8?logo=go&logoColor=white)                                                     |
| **Core-Client**   | The client application for our user interface.      | [www.embloy.com](https://www.embloy.com)               | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-core-client)   | ![TypeScript](https://img.shields.io/badge/TypeScript-3178c6?logo=typescript&logoColor=white)                              |
| **Genius-Client** | The client application for our recruiter dashboard. | [genius.embloy.com](https://genius.embloy.com)         | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-genius-client) | ![JavaScript](https://img.shields.io/badge/TypeScript-3178c6?logo=typescript&logoColor=white)                              |
| **Developers**    | The developer documentation.                        | [developers.embloy.com](https://developers.embloy.com) | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-developers)    | ![JavaScript](https://img.shields.io/badge/JavaScript-f1e05a?logo=javascript&logoColor=black)                              |
| **API-Docs**          | The API documentation.                              | [docs.embloy.com](https://docs.embloy.com)             | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-api-collections)          | ![Postman](https://img.shields.io/badge/Postman-FF6C37?logo=postman&logoColor=white)                                       |
| **Examples**      | Example applications for Embloy integrations.       | [examples.embloy.com](https://examples.embloy.com)     | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-examples)      | ![Various](https://img.shields.io/badge/Various-000000?logo=github&logoColor=white)                                        |
| **About-Page**         | The about page for Embloy.                          | [about.embloy.com](https://about.embloy.com)           | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-website)         | ![Imba](https://img.shields.io/badge/Imba-14c1ba?logo=imba&logoColor=white) |

## SDKs

| SDK                   | Link                                                                                                                                       | Repository                                                                                                     | Total Downloads                                                                                                                                  |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Embloy-Node**   | [![npm version](https://img.shields.io/npm/v/embloy.svg?style=flat)](https://www.npmjs.com/package/embloy-node)                            | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-node)   | [![npm downloads](https://img.shields.io/npm/dt/embloy.svg?style=flat)](https://www.npmjs.com/package/embloy-node)                               |
| **Embloy-Python** | [![PyPI version](https://img.shields.io/pypi/v/embloy-sdk.svg?style=flat)](https://pypi.org/project/embloy-python)                         | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-python) | [![PyPI downloads](https://img.shields.io/pypi/dm/embloy-sdk.svg?style=flat)](https://pypi.org/project/embloy-python)                            |
| **Embloy-Go**     | [![Go Reference](https://pkg.go.dev/badge/github.com/embloy/embloy-go.svg)](https://pkg.go.dev/github.com/embloy/embloy-go)                | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-go)     | _unavailable_                                                                                                                                    |
| **Embloy-Ruby**   | [![gem version](https://img.shields.io/gem/v/embloy.svg?style=flat)](https://rubygems.org/gems/embloy)                                     | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-ruby)   | [![Gem downloads](https://img.shields.io/gem/dt/embloy.svg?style=flat)](https://rubygems.org/gems/embloy)                                        |
| **Embloy-Java**   | [![Maven Central](https://img.shields.io/maven-central/v/com.embloy/sdk.svg?style=flat)](https://search.maven.org/artifact/com.embloy/sdk) | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-java)   | _unavailable_                                                                                                                                    |
| **Embloy-PHP**    | [![Packagist Version](https://img.shields.io/packagist/v/embloy/embloy-php.svg)](https://packagist.org/packages/embloy/embloy-php)         | [![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/embloy/embloy-php)    | [![Packagist downloads](https://img.shields.io/packagist/dt/embloy/embloy-php.svg?style=flat)](https://packagist.org/packages/embloy/embloy-php) |

## Functionality Overview

### Quicklink

With Quicklink you can integrate Embloy into your web service. What PayPal is for transactions, Embloy-Quicklink is for applications. We designed Quicklink to be as easy to use as possible, requiring minimal effort to be integrated on your job posting site. All you have to do is add the "Apply with EMBLOY" button to your client and add one Endpoint to your server and the rest is managed by Embloy.
For more information, see the [Quicklink documentation](https://developers.embloy.com/docs/category/quicklink).

### Genius-Queries

Embedding Embloy content on external platforms made ease. Create a new Genius-Query and upload it to your social media platform to direct new applicants directly to your Embloy job application. For more information, see the [Genius-Queries documentation](https://developers.embloy.com/docs/category/genius).

### Application Proxy

The Application Proxy (see [./proxy](./proxy/)) is designed as a simple proxy and cache node for Embloy Quicklink. It can be used to integrate Embloy without using a Server-SDK or embedding any code on a third party site, allowing the third party to direct to a generic URL (apply.embloy.com) which then proxies the Quicklink request by fetching a request and client token remotely. For more information, see the [Application Proxy documentation](https://developers.embloy.com/docs/application-proxy).

### Third-Party Integrations

For ATS-Providers that want to provide an Embloy integration, see: https://developers.embloy.com/docs/guides/get-started-partners/

For companies that want to integrate Embloy into their system, see: https://developers.embloy.com/docs/guides/get-started-integrations/

### User Authentication

Users can set up an account with their email address and password, or choose to log in using the OAuth2.0 services
provided by Google, GitHub, Microsoft and LinkedIn. Once an account is created, it needs to be verified by clicking on the email.

Passwords are instantly hashed using [bcryt](https://en.wikipedia.org/wiki/Bcrypt) and stored in the database as a
hash. In case a user forgets their password, it can be reset via standard email authentication.

To skip the verification process during applications new users can also verify their account by requesting a OTP via email.

For an optimal user experience, it is recommended to fill out the 'Preferences' field under 'My Profile'.
To log into the application, users can use the aforementioned OAuth2.0 services or enter their password.
If a user forgets their password, they can reset it by providing their email address and following the specified
procedure in the email.

### Subscriptions

Embloy partners with Stripe for simplified billing. Most Embloy services can be used for free, but for verification, the user needs to be subscribed to one of three subscription plans:

- Embloy-Free
- Embloy-Smart
- Embloy-Genius

To create a company account and access all features, a user must be subscribed either to Embloy-Smart or Embloy-Genius.
Subscriptions are per default on a monthly basis, but can be customized to be dependent on API use. For more information, see the [subscription documentation](https://developers.embloy.com/docs/category/subscriptions).

### Job Postings and Company Boards

Subscribed company users can create new job postings and, depending on the employer's liking, also define up to 50 customized questions as well as file and filetype requirements.
This customization includes specifying whether an application option is required for the application, and if required, employers can also indicate their preferred file formats, and answers to ensure that the applications meet the employer's expectations.

A company can then publish a job board (e.g., [embloy.com/en-US/board/embloy](https://www.embloy.com/en-US/board/embloy)) allowing other users to view the job listings and apply for the positions.

### Managing Applications for Available Jobs

The system is capable of managing jobs and applications, and notifying the employer when a new application is submitted via direct push notifications, as well as notifying the applicant when their application is accepted or rejected.

All notifications are sent via [SMTP](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol).
Uploaded images and files are encrypted and stored GDPR compliant on Amazon S3 servers in Frankfurt, Germany.

### Filtering of Available Jobs and Creating an "Intelligent" Feed

The job feed delivers personalized job recommendations based on the user's preferences and behavior.
The user can also utilize our advanced search functionality, which includes comprehensive filtering and sorting options
for direct job exploration.

Additionally, our interactive map interface, powered by the [OpenStreetMap API](https://www.openstreetmap.org), provides
a visual overview of job opportunities.

## How it Works

To get started, simply visit [www.embloy.com](http://embloy.com/) and create a new account or log in with an existing
account. It's that easy!

## Running on Docker

Go into the project directory and run: \
`$ docker build -t embloy .`\
`$ docker run -it -p 3000:3000 embloy `

To deploy to docker-hub: \
`$ docker tag embloy:latest <docker-username>/<docker-repository>`\
`$ docker push <docker-username>/<docker-repository>`

## Config

> **NOTE**: _You only need to follow these steps if you wish to contribute and need to test your changes locally_

<details>
  <summary> 1. Prerequisites </summary>

- Install Ruby 3.2.2

- Install Rails 7

- Install Postgresql 16

- Open pgAdmin4

- Add a new server

</details>

2. Create a `.env` file with the content of `.example.env`

<details>
  <summary> 3. Start the server </summary>

  If you wish to experiment on our backend or contribute to our front end, you can test your changes by starting a local
  server.

  1. Run `$ rails db:create` to create all necessary tables in your development database.
  2. Run `$ rails db:migrate` to migrate your changes to the database.
  3. Run `$ rails server` to start the server.
  4. Open your browser and navigate to `localhost:3000` to view the application.

</details>


<details>
  <summary> 4. Setup Stripe webhook </summary>
  To enable subscriptions and Embloy Quicklink, make sure to have StripeCLI installed and have an active webhook:
  
  ```Bash
  ./stripe listen --forward-to localhost:3000/pay/webhooks/stripe
  ```

</details>

## License

### Licensed under

> GNU AFFERO GENERAL PUBLIC LICENSE v3.0 ([agpl-3.0](https://www.gnu.org/licenses/agpl-3.0.en.html)).

## Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by anyone, as
defined in the GNU AFFERO GENERAL PUBLIC LICENSE v3.0 license, shall be licensed as above, without any additional terms
or conditions.

## What's next

See [our GitHub issues](https://github.com/embloy/embloy-core-server/issues) for a list of known issues and planned features.

---

© Carlo Bortolan, Jan Hummel

> Carlo Bortolan &nbsp;&middot;&nbsp;
> GitHub [@carlobortolan](https://github.com/carlobortolan) &nbsp;&middot;&nbsp;
> contact via [bortolanoffice@embloy.com](mailto:bortolanoffice@embloy.com)
>
> Jan Hummel &nbsp;&middot;&nbsp;
> GitHub [@github4touchdouble](https://github.com/github4touchdouble) &nbsp;&middot;&nbsp;
> contact via [hummeloffice@embloy.com](mailto:hummeloffice@embloy.com)
