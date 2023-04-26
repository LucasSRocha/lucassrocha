#!/bin/bash
# The definitive guide to setup my Python workspace
# Based on: https://gist.github.com/henriquebastos/0a45c39115ca5b3776a93c89dbddfacb

# This fork is supposed to work with MacOS, Debian distros and Fedora 22+.

USER_OS=0

if [[ $(command -v uname) ]]; then
  case $(uname) in
    'Linux')
    while ! [[ "$USER_OS" =~ ^([2,3]) ]]; do
      read -r -p "Your distro is based on what?
2 - Debian based (i.e. Ubuntu, Debian, MX, Mint, ...)
3 - Red hat based (i.e. Fedora, CentOS, ...)
" USER_OS
    done
      ;;
    'Darwin')
      USER_OS=1
      ;;
    *) ;;
  esac
fi

while ! [[ "$USER_OS" =~ ^([1,2,3]) ]]; do
  read -r -p "Which OS are you using?
1 - MacOS
2 - Debian based Linux
3 - Fedora
" USER_OS
done


read -r -p "Install py 2.7 as well? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
  INSTALL_PYTHON2=1
else
  INSTALL_PYTHON2=0
fi

#Python versions
PY3=3.10.4
PY2=2.7.18

# Tools packages
PY3TOOLS="pytest pandas requests"
PY2TOOLS="requests"

VENVS=~/.ve
PROJS=~/workspace

# Venv Names
JUPYTER=jupyter38
TOOLS3=tools38
IPYTHON2=ipython27
TOOLS2=tools27

# Shell Path
case $(echo $SHELL | rev | cut -d '/' -f 1 | rev) in
bash )
SHELL_PROFILE_DIR=~/.bashrc
;;
zsh )
SHELL_PROFILE_DIR=~/.zshrc
;;
ksh )
SHELL_PROFILE_DIR=~/.profile
;;
fish )
SHELL_PROFILE_DIR=~/.config/fish/config.fish
;;
* )
SHELL_PROFILE_DIR="<your profile path>"
;;
esac

# Package manager for each OS
if [ $USER_OS = 1 ]; then
  if ! [[ $(echo `command -v brew`) ]];then
    echo 'Brew not found, please go through the install process. by running: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit
    # bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # would be good if we could install brew here but we need further testing.
  fi
	PACKAGE_MANAGER=brew
	OSX_MAJOR_VERSION=$(sw_vers -productVersion | cut -d '.' -f 1)
	OSX_MINOR_VERSION=$(sw_vers -productVersion | cut -d '.' -f 2)
elif [ $USER_OS = 2 ]; then
	PACKAGE_MANAGER=apt-get
elif [ $USER_OS = 3 ]; then
	PACKAGE_MANAGER=dnf
else
	exit 1
fi

cat <<"EOT" >> $SHELL_PROFILE_DIR

# Aliases
alias ga="git add"
alias gd="git diff"
alias gs="git status"
alias gc="git commit -m"
alias gam="git commit -am"

EOT

# Install dependencies

if [ $USER_OS = 1 ]; then
	# Install Mac dependencies
	$PACKAGE_MANAGER install openssl readline zlib sqlite3 xz

	# Install Pyenv
	$PACKAGE_MANAGER install pyenv
	$PACKAGE_MANAGER install pyenv-virtualenv
elif [ $USER_OS = 2 ]; then
	# Install Debian dependencies
	sudo $PACKAGE_MANAGER update
	sudo $PACKAGE_MANAGER install --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

	# Install Pyenv
	curl https://pyenv.run | bash
elif [ $USER_OS = 3 ]; then
	# Install Fedora >= 22 dependencies
	sudo $PACKAGE_MANAGER install make gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel

	# Install Pyenv
	curl https://pyenv.run | bash
else
	exit 1
fi

# All my virtualenvs are here...
mkdir -p $VENVS

# All my projects are here...
mkdir -p $PROJS

# Setup shell profile

echo "# Virtualenv-wrapper directories" >> $SHELL_PROFILE_DIR
echo "WORKON_HOME=$(echo $VENVS)" >> $SHELL_PROFILE_DIR
echo "PROJECT_HOME=$(echo $PROJS)" >> $SHELL_PROFILE_DIR

cat <<"EOT" >> $SHELL_PROFILE_DIR

# Pyenv initialization
PYENV_ROOT="$HOME/.pyenv"
if which pyenv > /dev/null; then PATH="$PYENV_ROOT/bin:$PATH"; fi
EOT

PATH="$HOME/.pyenv/bin:$PATH"

if [ $USER_OS = 1 ]; then
cat <<"EOT" >> $SHELL_PROFILE_DIR
eval "$(pyenv init -)"
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi
EOT

# Initialize pyenv
eval "$(pyenv init -)"
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

else
cat <<"EOT" >> $SHELL_PROFILE_DIR
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOT

# Initialize pyenv
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
fi

# Install Python versions
if [ $USER_OS = 1 ]; then
	# Mojave has an specific condition to install because Apple...
	if [-a $OSX_MAJOR_VERSION = 10 -a $OSX_MINOR_VERSION = 14 ]; then
		SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.14.sdk MACOSX_DEPLOYMENT_TARGET=10.14 pyenv install $PY3
		if [ $INSTALL_PYTHON2 = 1 ]; then  SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.14.sdk MACOSX_DEPLOYMENT_TARGET=10.14 pyenv install $PY2; fi
	else
		pyenv install $PY3
		if [ $INSTALL_PYTHON2 = 1 ]; then pyenv install $PY2; fi
	fi
else
	pyenv install $PY3
	if [ $INSTALL_PYTHON2 = 1 ]; then pyenv install $PY2; fi
fi

# Prepare virtual environments
pyenv virtualenv $PY3 $JUPYTER
pyenv virtualenv $PY3 $TOOLS3
~/.pyenv/versions/$PY3/bin/pip install --upgrade pip
~/.pyenv/versions/$JUPYTER/bin/pip install --upgrade pip
~/.pyenv/versions/$TOOLS3/bin/pip install --upgrade pip

# Install Jupyter
~/.pyenv/versions/$JUPYTER/bin/pip install jupyter
~/.pyenv/versions/$JUPYTER/bin/python -m ipykernel install --user
~/.pyenv/versions/$JUPYTER/bin/pip install jupyter_nbextensions_configurator rise
~/.pyenv/versions/$JUPYTER/bin/jupyter nbextensions_configurator enable --user

# Install Python3 Tools
~/.pyenv/versions/$TOOLS3/bin/pip install $PY3TOOLS


# Install Virtualenvwrapper. Remember that it is tied to the py3 version that you specified.
if [ $USER_OS = 1 ]; then
 $PACKAGE_MANAGER install pyenv-virtualenvwrapper
else
  ~/.pyenv/versions/$TOOLS3/bin/pip install virtualenvwrapper
fi

# Protect lib dir for global interpreters
chmod -R -w ~/.pyenv/versions/$PY3/lib/

if [ $INSTALL_PYTHON2 = 1 ]; then
	# Prepare virtual environments
	pyenv virtualenv $PY2 $IPYTHON2
	pyenv virtualenv $PY2 $TOOLS2
	~/.pyenv/versions/$PY2/bin/pip install --upgrade pip
	~/.pyenv/versions/$IPYTHON2/bin/pip install --upgrade pip
	~/.pyenv/versions/$TOOLS2/bin/pip install --upgrade pip

	# Install Python2 Tools
	~/.pyenv/versions/$TOOLS2/bin/pip install $PY2TOOLS

	# Install Python2 kernel
	~/.pyenv/versions/$IPYTHON2/bin/pip install ipykernel
	~/.pyenv/versions/$IPYTHON2/bin/python -m ipykernel install --user

	# Protect lib dir for global interpreters
	chmod -R -w ~/.pyenv/versions/$PY2/lib/
fi

echo "# Virtualenv Wrapper initialization" >> $SHELL_PROFILE_DIR
echo 'PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"' >> $SHELL_PROFILE_DIR
echo "pyenv virtualenvwrapper" >> $SHELL_PROFILE_DIR

# Setup path order
if [ $INSTALL_PYTHON2 = 1 ]; then
	pyenv global $PY3 $PY2 $JUPYTER $IPYTHON2 $TOOLS3 $TOOLS2
else
	pyenv global $PY3 $JUPYTER $TOOLS3
fi

# Check everything
pyenv which python     | grep -q "$PY3" && echo "✓ $PY3"
pyenv which jupyter    | grep -q "$JUPYTER" && echo "✓ $JUPYTER"
pyenv which ipython    | grep -q "$JUPYTER" && echo "✓ ipython"
pyenv which pytest	   | grep -q "$TOOLS3" && echo "✓ $TOOLS3"

if [ $INSTALL_PYTHON2 = 1 ]; then
	pyenv which python2    | grep -q "$PY2" && echo "✓ $PY2"
	pyenv which ipython2   | grep -q "$IPYTHON2" && echo "✓ $IPYTHON2"
fi

echo "Adding Ipython venv discovery"

# # Ipython venv Script
eval "$(pyenv which ipython) profile create"
curl -L http://hbn.link/hb-ipython-startup-script > ~/.ipython/profile_default/startup/00-venv-sitepackages.py

echo "Done! Restart the terminal."