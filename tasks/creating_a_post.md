# Creating a post

Blogs aren't very interesting without having content. In this exercise you'll build a Rails form for creating and editing posts. A post should have roughly this shape:

```json
{
  "title": "My title",
  "created_at": "Mon Dec 20 17:20:23 EST 2021",
  "updated_at": "Tue Dec 21 17:20:23 EST 2021",
  "text": "This is my post. It is not long."
}
```

To create this form, you'll need to address the following:

1. Create a `Post` Model, View, and Controller. This is where the MVC in MVC framework comes from...
2. Create routes to your new edit and update functions in the Controller
3. Use Rails' form helpers to generate a form with a `textarea` for the content
4. Confirm that posts and their edits are being saved in your local PostgreSQL database


### Styling your form(s)

In the previous exercise you created a layout. This form should use that same layout. Otherwise, feel free to style this however you like!

### Getting help
You've already had a chance to go through the [Rails quickstart](https://guides.rubyonrails.org/getting_started.html), so topics like routing and generators - while perhaps not familiar - shouldn't be totally new. You may also get some value of watching [Rails blog in 30 minutes](https://www.youtube.com/watch?v=f-qY37JIdg0), although I'm not sure how this video has aged.

As always, you can also ask your onboarding buddy or drop a well-formed question into #product-dev.

#### General resources
1. [Rails generators](https://guides.rubyonrails.org/generators.html)
2. [Active Record](https://guides.rubyonrails.org/active_record_basics.html)
3. [MVC in Rails](https://stackoverflow.com/questions/1931335/what-is-mvc-in-ruby-on-rails)
4. [Form helpers](https://guides.rubyonrails.org/form_helpers.html)

#### Quick Review
- You learned...
  - How to generate a model, view, and controller via Rails generators
  - How to wire Rails up to a database
