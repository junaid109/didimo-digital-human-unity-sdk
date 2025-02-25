# Didimo Unity SDK

[Didimo](https://www.didimo.co/) provides a cloud-based automated service that enables the generation of digital humans
from a simple selfie, we call these didimos.

Utilising this code library and tools, you can easily integrate digital humans into your existing software and enable
your users to easily generate and load digital doubles of themselves directly into your experience, all at runtime.

All you need to get up and running after download is included in this README.

---

Following your decision to download this repo - our goal is to make it as easy and smooth as possible to get you
building software. Your didimos can be imported into the project by simple drag-and-drop at edit time, or they can be
loaded into the scene at runtime. No matter which approach you need, we've got you covered.

## Pre-requisites

This SDK has been built to work with Unity 2021.3.x LTS (from Unity 2021.3.1 onwards).


## Setup Process

1. Install via the package manager
   1. Go to Project Settings → Package Manager
      1. Add the following scoped registry
      ```
      Name: Didimo
      URL: https://package.openupm.com
      Scopes: com.didimo.sdk
      
   2. Open Unity's Package Manager, and make sure you refresh it
   3. On the `Packages:` drop down, select `My Registries`
   4. The available Didimo packages will be listed. Install the ones you want. We recommend starting with the `Core` package.
   5. Optionally, add any of the following modules, by repeating the previous 2 steps, with the URLs:

      * `Didimo SDK - Networking` For didimo API integration
      * `Didimo SDK - Mobile` For a communication layer between android/iOS and Unity
      * `Didimo SDK - Oculus` For integration with Oculus
      * `Didimo SDK - Asset Fitter` For a tool used to fit apparel

2. Setup your project. You can do this by going to Window → Didimo Manager, and following the instructions, or by following these steps 
   1. Go to Project Settings → Graphics, and select `UniversalRP-HighQuality` as the render pipeline asset. 
   2. Go to Project Settings → Quality, and select `UniversalRP-HighQuality` as the render pipeline asset, for your desired
      quality level.
   3. Go to Project Settings → Player → Other Settings → Rendering. Set the colour space to linear.


3. Explore
   1. Open the `MeetADidimo` scene, by going to Window → Didimo Manager, and clicking the "open the Meet a didimo scene" link.
   2. TextMeshPro will be automatically installed by Unity at this point if it wasn't already, by prompting you to
   Import TMP Essentials, which is required for the examples
   3. You should now be able to press play and see the included talking didimos.
      **If you do not**, then please **regenerate didimos**.
      See [Known Import Issues](#Known-Import-Issues) and [Support](#Support) for further assistance. 
   4. It's possible to generate didimos via the didimo API directly from Unity.
   Simply [Create an account](https://developer.didimo.co/docs/creating-your-account)
   Then see [Generating a didimo](https://developer.didimo.co/docs/creating-a-didimo).


---

# Already have a glTF importer?

For runtime loading of didimos, you can keep both importers without any issues. But for the **Unity Editor**, to import didimos directly into the project, Unity only allows one scripted importer per file extension. 
If you already have a glTF importer on your project, we will have a clash. To fix this, either:
* Delete your glTF library and use ours instead. Our glTF importer is based on [GLTFUtility](https://github.com/Siccity/GLTFUtility)
* If you need to keep your importer, you can add the script define symbol `USE_DIDIMO_CUSTOM_FILE_EXTENSION` to your project. This will make our importer register to the extension `.gltfd` instead. You will then be responsible to rename your didimo `.gltf` files into `.gltfd`. 
This will break our sample scenes, so if you need to evaluate the SDK first, we suggest you do it on a clean project.  

---


# SDK Contents

This project is broken down into the following modules:

* **Core** - Everything core to the SDK, including loading didimos where it handles animations, materials, speech, etc.
* **Mobile** - Add the ability of bi-directional communication between Unity and native Android or iOS applications.
* **Networking** - Allows for immediate interaction with the Didimo API.
* **Oculus** - Example integration with Oculus quest, and sample meeting room (multiplayer).
* **Asset Fitter** - A tool used to fit the apparel (clothing, accessories and hairstyle) of a 3rd Party avatar into a didimo.


Every module may contain a `Samples` folder, where example assets and scenes of said module can be found. You can import 
samples into your project through the Package Manager interface, after adding the module to your project. Go to Window →
Package Manager, select the Didimo SDK module you want to see samples from, and click one of the "Import" buttons.


---

## Included

* Code Examples
* Set up tools / authentication
* Importing tools (edit/runtime)
* Cloud API Tools
* Integrations with other platforms such as AWS Polly and ARKit
* Animation tools
* Hair library and 'Fitting Service'
* Idle Animation Library

Be sure to check out the [Digital Human Specifications](https://link.didimo.co/39dkEH0), best practices and
the [SDK Guide](https://link.didimo.co/3tPAWPY) on our [Developer Portal](https://link.didimo.co/3Ckogna).


---

## Oculus Integration


1. If you wish to build for Oculus, install the package [Oculus Integration](https://link.didimo.co/3tJLcJs)
   
   1.1 Add the `Oculus Integration` package to your account through Unity's Asset Store
   
   1.2 Download and install the `Oculus Integration` package, through Unity's Package Manager. It should be listed
   
   under `Packages: My Assets`. Refresh the Package Manager if required
   
   1.3 Follow the instructions to update Oculus and restart Unity

You may be asked to update a number of Oculus related tools and restart Unity BEFORE the plugin will be installed. If
you restart - check to see if the plugin still needs to be installed. A successful install will result in an `Oculus`
folder in the Assets folder.

_Didimo has tested this against version 32.0 which was published on the 30th August 2021._


2. [Continue with setting up the SDK](#Setup-Process).

---

## ARKit Integration

1. **If you wish to capture and record face movements using ARKit**, install the package [Live Capture](https://link.didimo.co/3ABEI1G) from Unity.
   
   2.1 Open Unity's Package Manager
   
   2.2 Under the `+` button, select `Add package from git URL...`
   
   2.3 Enter `com.unity.live-capture@1.0.1` and press `Add`

Additionally, you will need the companion app [Unity Face Capture](https://apple.co/3nXoGfl) installed on an iPhone or iPad that supports ARKit face tracking.

_**Warning:**
This package is marked as preview and therefore the installation process may be subject to changes._

2. [Continue with setting up the SDK](#setup-process).

---

## Known Import Issues

* We cannot control the order with which Unity imports assets. If the .glTF files of your didimos get imported before any of
  its dependencies, then the didimo will fail to import.
* If you open the `MeetADidimo` scene and don't see any didimos, go to Window → Didimo Manager, and click the `Reimport didimos`
  button.

---

# Further Documentation

Further detail is explained in the [Developer Portal](https://link.didimo.co/3Ckogna) - "Getting Started" docs related
to software creation are:

* [Best Practices](https://link.didimo.co/3nE5cfj)
* [Unity SDK](https://link.didimo.co/3tPAWPY)
* [Accessory Fitting Service](https://link.didimo.co/3nzssv8)
* [Cloud API](https://link.didimo.co/39aNgAL)

---

# Contributing and Reporting bugs

Thank you for contributing and trying our product!
For bug reports, use github's issue tracker.

For pull requests:

1. Fork the repository to your GitHub account
2. Clone the repository to your machine
3. Create a new branch with a short descriptive name
4. Commit your code changes
5. Open a pull request, with a detailed description of your changes
6. We will test your changes internally, and if everything goes well, we will include them in our next release

---

# License

This SDK uses the [Didimo Source Code License](https://link.didimo.co/3hDyTcW). Read
our [Privacy](https://link.didimo.co/3AiXniS) page for more information on our license and privacy policies.

---

# Support


Detailed documentation can be read on our [Developer Portal](https://link.didimo.co/3Ckogna) and 

* Feature Request: [featurerequest@didimo.co](mailto:featurerequest@didimo.co)
* Technical Support: [support@didimo.co](mailto:support@didimo.co)
* Service Uptime Checker: https://status.didimo.co/