This is a Delphi translation of the VST3 Protocol.
It supports many of the VST3 aspects, but not all.
The main class is TVST3Instrument which implements the functionality of a VST3 Plugin.
It is a combined Processor/Controller and implements the following:
- Audio processing (synth or effect), two channel only. 
- Midi CC processing
- Parameter processing
- Presets
- Tempo / Playstate.

There is a simple example which implements some of the basics in an Audio Gain VST. 

That's IT for the moment.

I am planning to expand this software if some people are interested in it.
But I am not user if anyone is still developing in Delphi. 
So if you have any intereset let me know.
The main parts to improve would be:
- Documentation! That's quite some work.
- Testing! I only tested the basic plugin and a few of my own plugins (which use this 
stack to wrap my VST2 plugins) and it works... In Reaper! Not tested in any other host.

I really would like to expand this to something like (the VST part of ) the old DelphiAsioVST stuff which was popular in the past.
Delphi is still a very strong language ans with the community edition is my favorite platform.
See my website www.ermers.org for other stuff.

So..if you want to give it a try... just load the example project and hit Build. (You must have CodeSite installed, see the GetIt Package manager).
Copy the VST3 to your plugin directory and who knows...
  

