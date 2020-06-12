# pVoice
Mumble voice chat using FiveM's murmur implementation 

## Config file
*Do not copy paste this, comments are not supported by JSON*
```js
{
    "debug": false, // Toggle logs
    "switchModeDefaultKey": "f6", // to switch voice mode
    "use3dAudio": true, // use fivem's mumble 3d audio
    "useSendingRangeOnly": true, // use fivem's sending range ony
    "phrases": { // to translate
        "switchVoiceMode": "Switch voice mode",
        "switchModeNotif": "The intensity of your voice has been set on mode:"
    },
    "voiceModes": [ // supported voices modes
        { "name": "Whisper", "distance": 4 },
        { "name": "Normal", "distance": 10 },
        { "name": "Yell", "distance": 20 }
    ]
}
```

## Requirements
- FiveM Server
- pVoice