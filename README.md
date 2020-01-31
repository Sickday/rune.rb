# RuneScape Ruby Suite [dev]


## About

**RuneScape Ruby Suite** is a passion project I've been working over the passed couple years. I wanted to make a server suite that is fun use, and easy to extend. I'm sure many would frown on the use of Ruby for this entire project, but the reason behind it is more rooted in the fact that it's generally easier for someone who is not tenured in Software Development to follow what's going on. Take this project and make it your own. It's here for you to expand upon, experiment with, and share with everyone. 

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

## Usage

The server is far from a state where it could even be used. There's still much work to be done before it can be used for anything at all!


## Contribution

Want to contribute? Great!

Reach out to me (*Patrick*) on Discord. (**Sickday#0001**)
Or send me an email. (**Sickday@pm.me**)

## Current Contributors

| Contributor | Role | Contact |
| ----------- | ---- | ------- |
| Patrick W | Maintainer + Developer | Sickday@pm.me/**Sickday#0001** |

[Logs]: http://jco.xyz

#### P.S.

> Hi.
>
> Quick background: I'm not a programmer and this project is a big learning experience for me. I do this all in free-time and have not (nor do I plan to) develop software professionally. That's not to say I don't want to write great code, but I don't expect to be landing any Software Dev jobs any time in the future nor is it my passion. I only ask that you have some patience with me and everyone else working on the project; **we're trying as hard as we can**. As much as we'd like to be, we're not all incredibly talented programmers. This is just a pass-time. Try to keep in mind the immortal words of Bill and Ted, "Be excellent to each other." 8}

> Kind regards,
> Pat W.