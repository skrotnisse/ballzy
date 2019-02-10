<p align="center">
  <img src="/screenshots/screenshot_1.png" width="450" title="Main menu">
</p>

<h3>Ballzy</h3>
Ballzy is a pong-like game for the NES. It's written in 6502-assembler.

<h4>Installing & Running</h4>
These instructions should hopefully work for any newer Ubuntu linux setup.

Install the 'fceux' NES emulator:
<pre><code>sudo apt install fceux</code></pre>

Install the cc65 toolset from here:
<pre><code>https://cc65.github.io/</code></pre>

Clone the repo and build the project:
<pre><code>git clone https://github.com/skrotnisse/ballzy
cd ballzy
make</code></pre>

Running make will both build and run the game at the moment.

<h4>TODOs</h4>
The code is in heavy need of refactoring. There's lots of duplicate code and stuff that should be sorted out. I also plan to add more features and content, such as music/soundfx.
