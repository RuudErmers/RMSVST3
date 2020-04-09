This is a Delphi translation of the VST3 Protocol.
In fact, it is also an implementation for Fruityplug.
It supports many of the VST3 aspects, but not all.
The main class is TVSTInstrument which implements the functionality of a VST3/Fruityplug Plugin.
It is a combined Processor/Controller and implements the following:
- Audio processing (synth or effect), two channel only. 
- Midi CC processing
- Parameter processing
- Presets
- Tempo / Playstate.

There is a simple example which implements some of the basics in an Simple Synthesizer VST. 
There is also documentation on how to implement this wrapper code.
Tested in Reaper and FL Studio (rudimentair).

Thanks to the Kenneth Rundt for help on testing in several hosts and pointing out a lot of
failures and helping to solve them. We are almost there...

I am planning to expand this software if some people are interested in it.
But I am not sure if anyone is still developing in Delphi. 
So if you have any intereest let me know.

I really would like to expand this to something like (the VST part of ) the old DelphiAsioVST stuff which was popular in the past.
Delphi is still a very strong language ans with the community edition is my favorite platform.
See my website www.ermers.org for other stuff.

So..if you want to give it a try... just load the example project(s) and hit Build. (You must have CodeSite installed, see the GetIt Package manager).
Copy the VST3 to your plugin directory and who knows...
  

