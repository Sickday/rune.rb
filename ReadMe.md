
[![coverage](https://gitlab.com/sickday/rune.rb/badges/master/coverage.svg?job=test_app)](https://rubydoc.info/github/Sickday/rune.rb/master)
[![Gem Version](https://badge.fury.io/rb/rune.rb.svg)](https://rubygems.org/gems/rune.rb)
![GitHub](https://img.shields.io/github/license/Sickday/rune.rb)

## About

**Rune.rb** is a game server written in Ruby targeting the 2006 era of RuneScape (or the 317-377 protocols).

## Usage

You'll need an appropriate 317 or 377 client to connect to the server application.**

### Dependencies
#### arch
```shell
sudo pacman -S base-devel postgresql-libs sqlite
```

#### ubuntu
```shell
sudo apt install build-essential libpq-dev libsqlite3-dev
```

Clone the repo
```shell
git clone https://gitlab.com/sickday/rune.rb.git
```

Install gem dependencies and use the included `boostrap.rb`
```shell
cd rune.rb/
bundle install
ruby boostrap.rb
```

### Connecting

Modify the JSON files located in `assets/config` to change application behavior.
## Current Contributors

| Name | Role | Contact |
| ----------- | ---- | ------- |
| Patrick W. | Maintainer | Sickday@pm.me or nice#3008 |


<sub><sub>**During my tests, I used [refactored-client](https://github.com/Rabrg/refactored-client) or [refactored-317](https://gitlab.com/jscranton55/refactored-317) for all 317 testing. I exclusively used [refactored-client-377](https://github.com/Promises/refactored-client-377) for any and all 377 testing.</sub></sub>

<sub><sub><sub><sub>If you're viewing this repo on github, you're looking at a mirror. The main repo is hosted on gitlab [here](https://gitlab.com/sickday/rune.rb). Issues are enabled only on the main repo.

