[![coverage](https://gitlab.com/sickday/rune.rb/badges/master/coverage.svg?job=test_app)](https://rubydoc.info/gems/rune.rb)
[![Gem Version](https://badge.fury.io/rb/rune.rb.svg)](https://badge.fury.io/rb/rune.rb)
## About

**Rune.rb** is a game server written in Ruby targeting the 2006 era of RuneScape (or the 317-377 protocols).

## Usage

Install dependencies according to your distro.

### arch
`sudo pacman -S base-devel postgresql-libs sqlite`

### ubuntu
`sudo apt install build-essential libpq-dev libsqlite3-dev`

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

Modify the JSON files located in `assets/config` to change application behavior.


## Current Contributors

| Name | Role | Contact |
| ----------- | ---- | ------- |
| Patrick W. | Maintainer | Sickday@pm.me or nice#3008 |

<sub><sub><sub><sub>If you're viewing this repo on github, you're looking at a mirror. The main repo is hosted on gitlab [here](https://gitlab.com/sickday/rune.rb). Issues are enabled only on the main repo.

