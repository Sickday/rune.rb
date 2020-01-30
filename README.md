# (R)une(S)cape (R)uby (S)uite


## About

I wanted to make a server suite that is fun use, and easy to extend. I'm sure many would frown on the use of Ruby for this entire project, but the reason behind it is more rooted in the fact that it's generally easier for someone who is not tenured in Software Development to follow what's going on. Ruby is a fun language to use and it's very expressive. A good portion of Ruby code you see these days can be read in individual lines, and still make sense! For this reason (and the fact Ruby is the only language I'm comfortable using) Ruby is the language of choice here. 

Take this project and make it your own. It's here for you to expand upon, experiment with, and share with everyone. 

Feedback is always welcome.



## Installation

Currently, this suite has no C-extensions. This means you will not need to build the project, however there is an extensive list of dependencies for this project that DO have C-extensions. You'll need to have development packages installed if you're using an *nix Operating system, or you'll need devkit installed alongside Ruby if you're using Windows.
* Note: Some GNU/Linux-based systems will not ship with packages that are needed to build native extensions. If that is the case for you, refer to your distributions documentation for further information on how you can obtain package development packages.

If you're using a debian-based or ubuntu-based system, it should be as simple as running:
```shell
$ sudo apt install build-essential
```

If you're using an Arch-based system:
```shell
$ sudo pacman -S base-devel
```

Solus would use:
```shell
$ sudo eopkg it -c system.devel
```

To get everything started up, run the following commands.

```shell
$ git clone https://gitlab.com/sickday/rsrs.git
$ cd rsrs
$ bundle install
```

## JAGGRAB

You'll need to acquire your own cache. By default **JAGGRAB is enabled**, and it will look for cache files within the the `data/cache/[revision]` directory. Be sure to place your cache there.


## Usage

After all necessary gems have been downloaded and installed, you can run the server with:

```shell
$ ruby node.rb
```
This will start a local server that will accept connections from port **43594** and the JAGGRAB server will be started on **43595**.

You can run the server without JAGGRAB using the following:

```shell
$ ruby bootstrap.rb --no-jaggrab
```

or shorthand

```shell
$ ruby bootstrap.rb -j
```

As for a Client, I also cannot supply that. I've personally been using [Major's Refactored #317 Client](https://gitlab.com/jscranton55/refactored-317).


## Contribution

Want to contribute? Great!

Reach out to me (*Patrick*) on Discord. (**Sickday#0001**)
Or send me an email. (**Sickday@pm.me**)

## Current Contributors

| Contributor | Role | Contact |
| ----------- | ---- | ------- |
| Patrick W | Maintainer | Sickday@pm.me/**Sickday#0001** |


Blog for changelog/updates coming soon(tm)

#### P.S.

> Hi.
This project is as much a learning experience for me as it is for anyone else. I do this all in free-time and have not (nor do I plan to) develop software professionally. That's not to say I don't want to write great code, but I don't expect to be landing any Software Dev jobs any time in the future nor is it my passion. I only ask that you have some patience with me and everyone else working on the project; **we're trying as hard as we can**. As much as we'd like to be, we're not all incredibly talented programmers. This is just a passtime. Try to keep in mind the immortal words of Bill and Ted, "Be excellent to each other." 8}

> Kind regards,
> Pat W.