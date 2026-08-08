# Bridgetown Website README

Welcome to your new Bridgetown website! You can update this README file to provide additional context and setup information for yourself or other contributors.

## Table of Contents

- [Bridgetown Website README](#bridgetown-website-readme)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Install](#install)
  - [Development](#development)
    - [Commands](#commands)
  - [Deployment](#deployment)
  - [Contributing](#contributing)

## Prerequisites

- [Ruby](https://www.ruby-lang.org/en/downloads/)
  - `>= 3.3`
- [Bridgetown gem](https://gems.bridgetownrb.com/)
  - `gem install bridgetown -N`
- [Node](https://nodejs.org)
  - `>= 22`

## Install

```sh
cd bridgetown-site-folder
bundle install && npm install
```
> Learn more: [Bridgetown Getting Started Documentation](https://www.bridgetownrb.com/docs/).

## Development

To start your site in development mode, run `bin/bridgetown start` and navigate to [localhost:4000](https://localhost:4000/)!

Check out [plugins](https://www.bridgetownrb.com/plugins/) if you're looking to add functionality or a theme to your site.

### Commands

```sh
# running locally
bin/bridgetown start

# build & deploy to production
bin/bridgetown deploy

# load the site up within a Ruby console (IRB)
bin/bridgetown console
```

> Learn more: [Bridgetown CLI Documentation](https://www.bridgetownrb.com/docs/command-line-usage)

## Managing Events & Social Media

We use a custom CLI script (`bin/event`) to manage meetup posts and automatically publish them to our social media channels (Mastodon and Bluesky).

**1. Create a new event**
```sh
bin/event new 2026-08-20 "Intro to Hotwire"
```
This generates a new markdown post in `src/_posts/` with the correct boilerplate front matter. You can then edit the file to add details like the `meetup_link`.

**2. Publish and announce on social media**
```sh
bin/event publish
```
This launches an interactive wizard that lets you:
- Select an event from a reverse-chronological list of all posts.
- Choose a post template (Original Announcement, Reminder, or Post-Event Recap).
- Edit the social media post text inline.
- Automatically publish the post to **Mastodon** and **Bluesky** using credentials stored in 1Password.

**Threaded Replies**: 
The first time you publish an event, `bin/event publish` will save the generated Mastodon and Bluesky URLs directly into the post's markdown front matter. If you run `bin/event publish` again for the *same* event (e.g. to send a Reminder or Post-Event recap), it will automatically fetch those URLs and post your new updates as **threaded replies** to the original post on both platforms!

## Deployment

You can deploy Bridgetown sites on hosts like statichost.eu and Render as well as traditional web servers by simply building and copying the output folder to your HTML root.

> Read the [Bridgetown Deployment Documentation](https://www.bridgetownrb.com/docs/deployment) for more information.

## Contributing

If repo is on GitHub:

1. Fork it
2. Clone the fork using `git clone` to your local development machine.
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
