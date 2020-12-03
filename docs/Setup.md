# Setup

Follow this document setup `rune.rb` locally. I've ran tests on several distributions and windows, but no testing has been done on macOS or OS X platforms. Steps for linux should be fairly similar to what would be done on macOS or OS X.

For the time being, I'd highly recommend this project be setup in a linux environment as the performance relies on `Process#fork` which is not easily available in Windows (`Process#spawn` won't work for us here unfortunately).

## Preliminary setup

#### Linux
1. Install Ruby 2.6.5 or later.
   * I used `rvm` - http://www.rvm.io/
   
2. Install package dependencies depending on your distro:
   #### Ubuntu/Debian
   `sudo apt install libpq-dev build-essential`
   #### Arch/Manjaro
   `sudo pacman -S postgresql-libs base-devel`
   #### Solus
   `sudo eopkg install -c system.devel`
   
   `sudo eopkg it postgresql-devel`
   

#### Windows
1. Install Ruby 2.6.5 or later **with devkit**. 
    * I used https://www.rubyinstaller.org/  during tests.
    
2. Install PostgreSQL 12.0 or later
    * I used https://www.enterprisedb.com/downloads/postgres-postgresql-downloads

## Project Setup

**1**. Clone the repo and install dependencies via `bundler`
* Clone the Repo:
```shell script
git clone --branch --single-branch scratch https://gitlab.com/sickday/rune.rb.git`
cd rune.rb
bundle install
```

**2**. Restore the `defs.sql`,`profiles.sql`, and `system.sql` files contained within the `scripts` folder. These will create 3 databases that will be used later in this setup.
* I used `psql` to restore these during tests. Check below command for an idea of how to go about this:

   `psql -U postgres -W -f /path/to/project/root/scripts/<file>.sql`
  
**3**. Set environmental variables within a `.env` file.
* Template `.env` below:
```dotenv
HOST='0.0.0.0'                          # The host address to bind to.
PORT=43594                              # The port to listen on.
TERM='xterm'                            # The terminal emulator [optional]
DEBUG=1                                 # Enable/Disable debug logging.
PROFILE_DATABASE='rune_rb_profiles'     # The name of the database containing profiles
DEFINITIONS_DATABASE='rune_rb_defs'     # The name of the database containing definitions
SYSTEM_DATABASE='rune_rb_system'        # The name of the database containing data relating to the server
DATABASE_USER='postgres'                # The name of the database user to use for connections
DATABASE_PASS='1234'                    # The name of the password to use when connecting with the above user
DATABASE_HOST='localhost'               # The host address of the machine hosting the databases
```

**4**. Run the `bootstrap.rb` script to deploy an Endpoint instance or create your own script that will spawn a `Endpoint` to accept sessions and a `World::Instance` to manage game entities.
```shell script
ruby boostrap.rb
```
**boostrap.rb**:
```ruby
require_relative 'app/rune'

TEST_WORLD = RuneRb::World::Instance.new
ENDPOINT = RuneRb::Net::Endpoint.new(TEST_WORLD)
ENDPOINT.deploy
```
