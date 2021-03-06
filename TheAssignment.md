## A Photo app using the 500px API

Process:

- *This should take about 2 hours for the basics, and up to a day for the Nice to Haves*
- *You will be working in a new Swift 2.0 Xcode project.*
- *Skip 3rd-party libraries, so you would not need Carthage or Cocoapods.*
- *make meaningful commits*
- *write unit tests if they make sense*
- *include a README.md detailing any thoughts, issues, comments etc. you would like to communicate*
- *reply with a zipped copy of the repo, or a link to a remote repo*


Develop an app that parses the JSON from [this](https://api.500px.com/v1/photos?feature=popular&consumer_key=vW8Ns53y0F57vkbHeDfe3EsYFCatTJ3BrFlhgV3W) endpoint, and presents the encoded photos in a `UITableView` with cells set up like this:

![Screenshot of what the cell should look like](IdealCellImage.jpg?raw=true "Screenshot of what the cell should look like")

i.e., show the photo, the photo's title, the user's thumbnail, and the user's name.

(API documentation is [here](https://github.com/500px/api-documentation/blob/master/endpoints/photo/GET_photos.md))

- tapping on a cell shows a detail view with the photo
- add paging to the detail view
- add search filtering for `title`

## Nice to haves

- support paging for the endpoint (see `current_page`, `total_pages`). As the user scrolls to the end, load more photos.
- instead of table view, use `UICollectionView`
- custom animations. E.g., animate in photo cells one by one
