![gif](https://raw.githubusercontent.com/BenEmdon/meal-deals/master/overall-low.gif)

## Inspiration
A lot of times you want to eat out with friends but you just can't decide where to eat. There's a lot of discussion back and forth, and you start wondering if you should just stay home to save some money and simplify it all. This is what inspired us to create Meal Deal, which is here to help you quickly find a nearby place to eat and also save money in the process.

It also doesn't help deciding where to eat when restaurant advertisements aren't engaging.
We came here to solve these problems.

## What it does

Meal Deal provides a new way of thinking about how restaurants can advertise deals to potential customers. Through a visual map and push notifications, we can provide hungry friends with deals near them.

A typical use case would be a night out with friends downtown, unsure of where to eat. You open the app and walk around and see 50 cents wings night at a local pub on the map.

There's a win-win for you as the user and for the business. You get an explorative way of seeking deals near you. The business will get to a fast way to engage potential customers, without waiting for views on social media or updating their website.

## How we built it
We took advantage of the real-time database that Firebase provides. It's a core piece of how we get live updated data. We built the clients on mobile for users and admin interfaces on the web.

![realtime](https://raw.githubusercontent.com/BenEmdon/meal-deals/master/realtime-low.gif)

Firebase’s real time data storage service was perfect for our use case. Here you can see a location and notification appear as a new deal hits the database. This is synced on all clients looking at our app (up to 100,000 clients).

## Accomplishments that we're proud of
A beautiful app with a cool set of features. We built something we would want to use.

## What we learned
Many implementation details of Firebase it's strong and weak points.

## What's next for Meal Deal
Get into Ycombinator :wink:
