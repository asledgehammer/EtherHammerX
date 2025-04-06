## About
EtherHammerX is a client-side anti-cheat framework for the game Project Zomboid. The framework aims to:
- Provide "out-of-the-box" anti-cheat protection against cheats like **EtherHack**.
- Fight anti-cheat tampering & bypassing.
- Provide servers with customizable and configurable anti-cheat keys & modules.

## Installation
EtherHammerX requires the following workshop items to work:
- [asledgehammer_utilities](https://steamcommunity.com/sharedfiles/filedetails/?id=3360195806) (Workshop ID: 3360195806)
- [modloader](https://steamcommunity.com/sharedfiles/filedetails/?id=3367051185) (Workshop ID: 3367051185)
- [etherhammerx](https://steamcommunity.com/sharedfiles/filedetails/?id=3367055125) (Workshop ID: 3367055125)

> **NOTE**: These utilities are separate workshop mods so modders can use them for other projects.

Next, download the files in this repository. Create a directory on your server's  `Zomboid/` folder `Zomboid/Lua/ModLoader/mods/EtherHammerX/` and paste the contents of this repository in there.

Lastly, in order for the anti-cheat to kick players, API needs to exist that isn't in the game by default.

Two server-patches provides this API:
- [EtherHammerX_Server_Patch (PZ build 41.76.18)](https://cdn.discordapp.com/attachments/1173450487853494423/1358319904809549915/EtherHammerX_Server_Patch_41.78.16.zip?ex=67f3697d&is=67f217fd&hm=19a5f40c6ec2b14e16c9df0ec503ae3b2101a31474b3951ec0e0d03db499a783&) (Only adds needed API)
- [CraftHammer V1.06_01 (PZ build 41.76.18)](https://cdn.discordapp.com/attachments/1173450487853494423/1173469990754717707/craftboid_41.78.16_v1.06_01.zip?ex=67f34b97&is=67f1fa17&hm=9df6398e0106cb8b26d23fe396624116407c6762d189057ad7dcc442963108de&) (A full server-side anti-cheat)

> **Developer's Note**: *CraftHammer* is a full server framework with a built-in packet analyser for hackers trying to manipulate the network to gain access to cheats and exploits in the game. This is also a dated anti-cheat (3+ years old) and could run into some issues. I'd recommend this however if you don't want this on your server I totally understand. That's why I provide the other option only adding the API to kick and ban players.

## Why is EtherHammerX installed this way?
This design allows EtherHammerX to send managed and compiled code to the game's client with layers of added security. The server and client code use generative values that only work for both player sessions and single server-cycles. Static workshop files can be easily read, overwritten, and disabled. A lot more work is required to reverse-engineer this framework because of how it is designed, **even if it's open-source.** 

This design also allows servers to **customize their security and add their own anti-cheat modules**, with or without my help. Diversity and open-source security allows servers to take matters into their own hands.

## Customization & Development
EtherHammerX is built around open-source security and customization. Customization and additional modules allows servers to take security into their own hands. Refer to the Wiki in this repository for help on customization and development of anti-cheat modules for your server.

## Support

![](https://i.imgur.com/ZLnfTK4.png)

## Discord Server

<https://discord.gg/u3vWvcPX8f>

If you like what I do and helped your community a lot, feel free to buy me a coffee!
<https://ko-fi.com/jabdoesthings>

<https://www.paypal.com/paypalme/JabJabJab>
