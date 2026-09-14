#!/bin/bash
echo "**************************************************"
echo " Setting up TDD/BDD Final Project Environment"
echo "**************************************************"

echo "*** Installing Python 3.9 and Virtual Environment"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3.9 python3.9-venv

echo "*** Making Python 3.9 the default..."
sudo update-alternatives --remove-all python3
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

echo "*** Checking the Python version..."
python3 --version

echo "*** Creating a Python virtual environment"
python3 -m venv ~/venv

echo "*** Configuring the developer environment..."
echo "# TDD/BDD Final Project additions" >> ~/.bashrc
echo "export GITHUB_ACCOUNT=$GITHUB_ACCOUNT" >> ~/.bashrc
echo 'export PS1="\[\e]0;\u:\W\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ "' >> ~/.bashrc
echo "source ~/venv/bin/activate" >> ~/.bashrc

echo "*** Installing Selenium for BDD"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y sqlite3 ca-certificates python3-selenium wget gnupg unzip jq

echo "*** Installing Google Chrome (Ubuntu's chromium-driver package needs a snap, which"
echo "*** doesn't work in a plain container, so we install Google's real .deb build instead)"
wget -q -O /tmp/google-chrome-signing-key.pub https://dl.google.com/linux/linux_signing_key.pub
sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg /tmp/google-chrome-signing-key.pub
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | \
    sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y google-chrome-stable

echo "*** Installing the chromedriver version that matches this Chrome build"
CHROME_VERSION=$(google-chrome --version | grep -oP '[0-9.]+' | head -1)
CHROMEDRIVER_URL=$(curl -s "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json" \
    | jq -r --arg v "$CHROME_VERSION" '.versions[] | select(.version==$v) | .downloads.chromedriver[]? | select(.platform=="linux64") | .url')
if [ -z "$CHROMEDRIVER_URL" ] || [ "$CHROMEDRIVER_URL" = "null" ]; then
    MAJOR=$(echo "$CHROME_VERSION" | cut -d. -f1)
    CHROMEDRIVER_URL=$(curl -s "https://googlechromelabs.github.io/chrome-for-testing/latest-versions-per-milestone-with-downloads.json" \
        | jq -r --arg m "$MAJOR" '.milestones[$m].downloads.chromedriver[]? | select(.platform=="linux64") | .url')
fi
wget -q "$CHROMEDRIVER_URL" -O /tmp/chromedriver.zip
unzip -o /tmp/chromedriver.zip -d /tmp/chromedriver-extract
sudo find /tmp/chromedriver-extract -name chromedriver -exec mv {} /usr/local/bin/chromedriver \;
sudo chmod +x /usr/local/bin/chromedriver
rm -rf /tmp/chromedriver.zip /tmp/chromedriver-extract
google-chrome --version
chromedriver --version

echo "*** Defaulting behave's DRIVER to chrome (no firefox/geckodriver installed here)"
echo "export DRIVER=chrome" >> ~/.bashrc

echo "*** Installing Python depenencies..."
source ~/venv/bin/activate && python3 -m pip install --upgrade pip wheel
source ~/venv/bin/activate && pip install -r requirements.txt

echo "*** Establishing .env file"
cp dot-env-example .env

echo "*** Starting the Postgres Docker container..."
make db

echo "*** Checking the Postgres Docker container..."
docker ps

echo "**************************************************"
echo " TDD/BDD Final Project Environment Setup Complete"
echo "**************************************************"
echo ""
echo "Use 'exit' to close this terminal and open a new one to initialize the environment"
echo ""
