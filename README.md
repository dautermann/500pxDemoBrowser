# LevelMoney500pxBrowser

A demo mobile app that browses through photos found at the [500px.com](https://500pxcom) website.

The reason the project starts off with the name LevelMoney is that this was a programming assignment for a potential role 
at this Capital One subsidiary.

## Where did this come from?

[This interviewer's programming assignment.](TheAssignment.md)

## What it comes with:

A UIImageView subclass that keeps track of which image URL is (or is about to be) displayed, used to cancel loading an in progress image if the cell or view has gone off screen.

A second UIImageView subclass that comes up with sexy circular user profile images.

## What you didn't ask for but you get for free:

Button in the top right brings up a picker that allows you to choose from different categories

I did a simple cache so pictures don't need to be re-downloaded every time.

## Things that I would do if I had more time:

1. Figure out why animations (e.g. sliding things) isn't as beautiful as it could be

2. It’s really cool that we can mix Foundation (NS-) types and Swift native types, but in my own production code I’m trying to keep things as native as possible.  I’d love to get rid of the [NSDictionary] picture array and make it totally native.

3. Put everything into Core Data to make it somewhat persistent and available off-line.

4. I can think of a few Unit / XCTests that I could possibly do, but I ran out of time to work these up.

5. More visual polish (translucent / opaque under the photo table / collection view on the main screen) and more user-friendly bells & whistles.

6. Improve error alerts & handling.

