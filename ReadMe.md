
## About

**Rune.rb** is a game server written in Ruby targeting the 2006 era of RuneScape (or the 317-377 protocols).

## Setup


#### Prerequisites
Debian/Ubuntu:
```shell
$ sudo apt install libpq-dev
```
ArchLinux:
```shell
$ sudo pacman -S postgresql-libs
```

Fedora:
```shell
$ sudo dnf install postgresql-libs
```

#### Repository
Clone the repo
```shell
$ git clone git@git.repos.pw:rune.rb/main.git
$ cd app
```

Install gem dependencies
```shell
$ gem install bundler # Only necessary if you do not already have bundler
$ bundle install
```

## Usage
You'll need an appropriate 317 or 377 client to connect to the server application.** You can launch an instance of the application using `rake`:
```shell
$ rake rrb:live:run # live launch
```
or
```shell
$ rake rrb:dev:run # debug launch
```

## Current Contributors

| Name | Role | Contact |
| ----------- | ---- | ------- |
| Pat W. | Maintainer | ZorgonPeterson#3008 |


<sub><sub>**During my tests, I used [refactored-client](https://github.com/Rabrg/refactored-client) or [refactored-317](https://gitlab.com/jscranton55/refactored-317) for all 317 testing. I exclusively used [refactored-client-377](https://github.com/Promises/refactored-client-377) for any and all 377 testing.</sub></sub>

<sub><sub><sub><sub>If you're viewing this repo on github, you're looking at a mirror. The main repo is hosted on gitlab [here](https://git.repos.pw/rune.rb/main). Issues are enabled only on the main repo.

