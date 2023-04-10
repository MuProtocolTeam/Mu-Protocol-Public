# Mu-Protocol

<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/MuProtocolTeam/Mu-Protocol-Public">
    <img src="docs/logo.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">Mu Protocol</h3>

  <p align="center">
    Stablecoin Solution on Sui Blockchain
    <br />
    <a href="http://ec2-44-204-83-185.compute-1.amazonaws.com/"><strong>Temporary UI</strong></a>
    ·
    <a href="docs/Stablecoin_LP_Marketplace.pdf"><strong>Stablecoin Market Design Doc</strong></a>
    <br />
    <a href="https://github.com/MuProtocolTeam/Mu-Protocol-Public/issues">Report Bug</a>
    ·
    <a href="https://github.com/MuProtocolTeam/Mu-Protocol-Public/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
    </li>
    <li><a href="#published-package">Published package</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

Mu Protocol offers the ultimate stablecoin solution on Sui blockchain to GameFi economy's inherent liquidity and payment problems and aims to become the financial service layer of the whole Sui ecosystem. On Mu Protocol, Any GameFi project on Sui can easily issue its utility or governance token, smoothly list it on desirable exchanges, efficiently bootstrap its liquidity, and successfully convert it into an effective payment method in and beyond its game economy. Non-GameFi projects can also find Mu Protocol the best solution to listing and bootstrapping its utility or governance token and furthering its growth.
[Stablecoin LP Marketplace design >>](docs/Stablecoin_LP_Marketplace.pdf)

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- GETTING STARTED -->
## Getting Started

### Install Sui

Please follow the intruction at https://docs.sui.io/build/install to install lastest version of Sui binaries and Sui client CLI.

### Connect to Sui Testnet

Please follow the intruction at https://docs.sui.io/build/devnet

<p align="right">(<a href="#readme-top">back to top</a>)</p>


## Published package 
### Sui Permanent Testnet

mu-core package: 0x04ec4a3987ade3b4ce54a555444e7fc26bf79a38a7a5af6d1e48c08260c0062d

oracle: 0x52a96dd8b78df0ad563e88301e3cc52ed97a44fcb3caf1a5e6a64dc090729c6d

musd metadata: 0x4632557a62ac9f295ef0c78b7eeb16134ead9da9f143b90130f2c5645f5e22b0

vault example: 0x2de4911476a1f7c11c85dcf1e82bfc947679ad2ad031eba35807a465339fb368

## Usage
### open mUSD vault
   ```sh
   sui client call --package 0x04ec4a3987ade3b4ce54a555444e7fc26bf79a38a7a5af6d1e48c08260c0062d --module vault --function open_vault --gas-budget 5000000
   ```
(More examples will follow)

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- ROADMAP -->
## Roadmap

- [x] mUSD, a collateralized debt position (CDP) stablecoin on Sui

- [ ] stablecoin LP Marketplace 
    - [x] AMM-type dex integration
    - [ ] ticket module (in progress, will be ready by 4/14)

See the [open issues](https://github.com/MuProtocolTeam/Mu-Protocol-Public/issues) for a full list of proposed features (and known issues)

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Email: muprotocol23@gmail.com

Telegram: @joey0707

Discord: JoeY#8088

Project Link: [https://github.com/MuProtocolTeam/Mu-Protocol-Public](https://github.com/MuProtocolTeam/Mu-Protocol-Public)

<p align="right">(<a href="#readme-top">back to top</a>)</p>





<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/MuProtocolTeam/Mu-Protocol-Public.svg?style=for-the-badge
[contributors-url]: https://github.com/MuProtocolTeam/Mu-Protocol-Public/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/MuProtocolTeam/Mu-Protocol-Public.svg?style=for-the-badge
[forks-url]: https://github.com/MuProtocolTeam/Mu-Protocol-Public/network/members
[stars-shield]: https://img.shields.io/github/stars/MuProtocolTeam/Mu-Protocol-Public.svg?style=for-the-badge
[stars-url]: https://github.com/MuProtocolTeam/Mu-Protocol-Public/stargazers
[issues-shield]: https://img.shields.io/github/issues/MuProtocolTeam/Mu-Protocol-Public.svg?style=for-the-badge
[issues-url]: https://github.com/MuProtocolTeam/Mu-Protocol-Public/issues
[license-shield]: https://img.shields.io/github/license/MuProtocolTeam/Mu-Protocol-Public.svg?style=for-the-badge
[license-url]: https://github.com/MuProtocolTeam/Mu-Protocol-Public/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/linkedin_username
[product-screenshot]: images/screenshot.png
