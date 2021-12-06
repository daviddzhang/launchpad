# README

Welcome to CollegeVine! This repo contains the skeleton of a web application built using the same tools we use for `app` (collegevine.com):
- Ruby on Rails
- PureScript
- Bootstrap + Dashkit
- PostgreSQL

Traditionally we've onboarded new engineers directly onto their teams and ramped them with progressively complicated tasks.
This works pretty well, but we often find ourselves teaching new engineers how all these different technologies fit together at the same time that we're working through complexities of our business.
Our goal is to get you productive and confident as quickly as we can, and our hope is that this code lab teaches you the basics of the tools and techniques you'll use every day as a CollegeVine engineer.

### Getting started
To get started, follow the instructions in our [app's readme](https://github.com/collegevine/app#readme), skipping steps 5,6, and 7. Skip steps 5-7 because they deal with loading the website's configuration, and this lab does not require any external configuration.

Once you've followed these steps, you should have an empty application running on `http://localhost:3000` that looks like this:

If you're seeing a pair of "hello" messages, you're good to get started!

### Building the app
1. Create a landing page
2. Create a layout
3. Create a Rails form for making a post using the layout
4. Add tests for the create-post form
5. Update the landing page to list all of the posts & titles, with links to the content
6. Create an inline form on posts that lets you comment without reloading the page, using Elmish
7. Create buttons on comments that enable up and down voting without reloading the page, using Elmish
8. Add a form for editing an existing post, this can be on a fresh page, complete with tests

### Getting help
If you're feeling stuck, don't hesitate to ask your onboarding buddy or drop a question in #product-dev.
However, in either case make sure to come prepared to explain what you've tried thus far and what you're trying to accomplish.
This makes it **much** more likely that you'll get a quick and helpful response

#### General resources
1. [Rails documentation](https://guides.rubyonrails.org/v5.2/)
2. [Elmish documentation](https://pursuit.purescript.org/packages/purescript-elmish)
3. [Guide to Purescript](https://jordanmartinez.github.io/purescript-jordans-reference-site/content/01-Getting-Started/01-Why-Learn-PureScript.html)
4. [Dashkit styleguide](https://themes.getbootstrap.com/preview/?theme_id=6063&show_new=)
5. [Bootstrap docs](https://getbootstrap.com/docs/5.0/getting-started/introduction/)
6. [PSQL docs](https://www.postgresql.org/docs/12/sql-syntax.html)
