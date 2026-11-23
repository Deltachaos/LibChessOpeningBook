--[[
  LibChessOpeningBook-1.0
  Lua opening books keyed by Polyglot (Zobrist) hashes.
  Other addons extend it by calling Register() after the library loads.
]]

local MAJOR, MINOR = "LibChessOpeningBook-1.0", 2
local Book = LibStub:NewLibrary(MAJOR, MINOR)
if not Book then return end

Book.books = Book.books or {}

--------------------------------------------------------------------------------
-- 32-bit XOR (Lua 5.1 / WoW have no native uint64)
--------------------------------------------------------------------------------
local bxor
do
  local bitlib = _G.bit or _G.bit32
  if bitlib and bitlib.bxor then
    bxor = bitlib.bxor
  else
    local floor = math.floor
    bxor = function(a, n)
      local r, p = 0, 1
      for _ = 0, 31 do
        local ba, bn = a % 2, n % 2
        if ba ~= bn then r = r + p end
        a, n = floor(a / 2), floor(n / 2)
        p = p * 2
      end
      return r
    end
  end
end

local function hex8(n)
  local hi = math.floor((n % 4294967296) / 65536)
  local lo = n % 65536
  return string.format("%04x%04x", hi, lo)
end

local function keyHex(high, low)
  return hex8(high) .. hex8(low)
end

--------------------------------------------------------------------------------
-- Polyglot Random64 (Fabien Letouzey). 781 unsigned 64-bit values as hex.
--------------------------------------------------------------------------------
local RANDOM_HEX = (
  "9d39247e33776d412af7398005aaa5c744db0150246235479c15f73e62a76ae275834465489c0c89" ..
  "3290ac3a203001bf0fbbad1f61042279e83a908ff2fb60ca0d7e765d58755c101a083822ceafe02d" ..
  "9605d5f0e25ec3b0d021ff5cd13a2ed540bdf15d4a672e32011355146fd563955db4832046f3d9e5" ..
  "239f8b2d7ff719cc05d1a1ae85b49aa1679f848f6e8fc9717449bbff801fed0b7d11cdb1c3b7adf0" ..
  "82c7709e781eb7ccf3218f1c9510786c331478f3af51bbe64bb38de5e7219443aa649c6ebcfd50fc" ..
  "8dbd98a352afd40b87d2074b81d7921719f3c751d3e92ae1b4ab30f062b19abf7b0500ac42047ac4" ..
  "c9452ca81a09d85d24aa6c514da275004c9f34427501b44714a68fd73c910841a71b9b83461cbd93" ..
  "03488b95b0f1850f637b2b34ff93c04009d1bc9a3dd90a943575668334a1dd3b735e2b97a4c45a23" ..
  "18727070f1bd400b1fcbacd259bf02e7d310a7c2ce9b6555bf983fe0fe5d82449f74d14f7454a824" ..
  "51ebdc4ab9ba30355c82c505db9ab0fafcf7fe8a3430b2413253a729b9ba3dde8c74c368081b3075" ..
  "b9bc6c87167c33e77ef48f2b83024e2011d505d4c351bd7f6568fca92c76a2434de0b0f40f32a7b8" ..
  "96d693460cc37e5d42e240cb63689f2f6d2bdcdae291966142880b0236e4d9515f0f4a5898171bb6" ..
  "39f890f579f92f8893c5b5f47356388b63dc359d8d231b78ec16ca8aea98ad765355f900c2a82dc7" ..
  "07fb9f855a9971425093417aa8a7ed5e7bcbc38da25a7f3c19fc8a768cf4b6d4637a7780decfc0d9" ..
  "8249a47aee0e41f779ad695501e7d1e814acbaf4777d5776f145b6beccdea195dabf2ac8201752fc" ..
  "24c3c94df9c8d3f6bb6e2924f03912ea0ce26c0b95c980d9a49cd132bfbf7cc4e99d662af4243939" ..
  "27e6ad7891165c3f8535f040b9744ff154b3f4fa5f40d87372b12c32127fed2bee954d3c7b411f47" ..
  "9a85ac909a24eaa170ac4cd9f04f21f5f9b89d3e99a075c287b3e2b2b5c907b1a366e5b8c54f48b8" ..
  "ae4a9346cc3f7cf21920c04d47267bbd87bf02c6b49e2ae9092237ac237f3859ff07f64ef8ed14d0" ..
  "8de8dca9f03cc54e9c1633264db49c89b3f22c3d0b0b38ed390e5fb44d01144b5bfea5b4712768e9" ..
  "1e1032911fa789849a74acb964e78cb34f80f7a035dafb046304d09a0b3738c42171e64683023a08" ..
  "5b9b63eb9ceff80c506aacf4898893421881afc9a3a701d66503080440750644dfd395339cdbf4a7" ..
  "ef927dbcf00c20f27b32f7d1e03680ecb9fd7620e731624305a7e8a57db91b77b5889c6e15630a75" ..
  "4a750a09ce9573f7cf464cec899a2f8af538639ce705b8243c79a0ff5580ef7fede6c87f8477609d" ..
  "799e81f05bc93f3186536b8cf3428a8c97d7374c60087b73a246637cff328532043fcae60cc0eba0" ..
  "920e449535dd359e70eb093b15b290cc73a1921916591cbd56436c9fe1a1aa8defac4b70633b8f81" ..
  "bb215798d45df7af45f20042f24f1768930f80f4e8eb7462ff6712ffcfd75ea1ae623fd67468aa70" ..
  "dd2c5bc84bc8d8fc7eed120d54cf2dd922fe545401165f1cc91800e98fb99929808bd68e6ac10365" ..
  "dec468145b7605f61bede3a3aef5330243539603d6c55602aa969b5c691ccb7aa87832d392efee56" ..
  "65942c7b3c7e11aeded2d633cad004f621f08570f420e565b415938d7da94e3c91b859e59ecb6350" ..
  "10cff333e0ed804a28aed140be0bb7ddc5cc1d89724fa4565648f680f11a27412d255069f0b7dab3" ..
  "9bc5a38ef729abd4ef2f054308f6a2bcaf2042f5cc5c2858480412bab7f5be2aaef3af4a563dfe43" ..
  "19afe59ae451497f52593803dff1e840f4f076e65f2ce6f011379625747d5af3bce5d2248682c115" ..
  "9da4243de836994f066f70b33fe090174dc4de189b671a1c51039ab7712457c3c07a3f80c31fb4b4" ..
  "b46ee9c5e64a6e7cb3819a42abe61c8721a007933a522a202df16f761598aa4f763c4a1371b368fd" ..
  "f793c46702e086a0d7288e012aeb8d31de336a2a4bc1c44b0bf692b38d079f232c604a7a177326b3" ..
  "4850e73e03eb6064cfc447f1e53c8e1bb05ca3f564268d999ae182c8bc9474e8a4fc4bd4fc5558ca" ..
  "e755178d58fc4e7669b97db1a4c03dfef9b5b7c4acc67c96fc6a82d64b8655fb9c684cb6c4d24417" ..
  "8ec97d2917456ed06703df9d2924e97ec547f57e42a7444e78e37644e7cad29efe9a44e9362f05fa" ..
  "08bd35cc383366159315e5eb3a129ace94061b871e04df75df1d9f9d784ba0103bba57b68871b59d" ..
  "d2b7adeeded1f73ff7a255d83bc373f8d7f4f2448c0ceb81d95be88cd210ffa7336f52f8ff4728e7" ..
  "a74049dac312ac71a2f61bb6e437fdb54f2a5cb07f6a35b387d380bda5bf785916b9f7e06c453a21" ..
  "7ba2484c8a0fd54ef3a678cad9a2e38c39b0bf7dde437ba2fcaf55c1bf8a442418fcf680573fa594" ..
  "4c0563b89f495ac340e087931a00930d8cffa9412eb642c168ca39053261169f7a1ee967d27579e2" ..
  "9d1d60e5076f5b6f3810e399b6f65ba232095b6d4ab5f9b135cab62109dd038aa90b24499fcfafb1" ..
  "77a225a07cc2c6bd513e5e634c70e3314361c0ca3f692f12d941aca44b20a45b528f7c8602c5807b" ..
  "52ab92beb96139899d1dfa2efc557f73722ff175f572c3481d1260a51107fe977a249a57ec0c9ba2" ..
  "04208fe9e8f7f2d65a110c6058b920a00cd9a497658a569856fd23c8f9715a4c284c847b9d887aae" ..
  "04feabfbbdb619cb742e1e651c60ba839a9632e65904ad3c881b82a13b51b9e2506e6744cd974924" ..
  "b0183db56ffc6a790ed9b915c66ed37e5e11e86d5873d484f678647e3519ac6e1b85d488d0f20cc5" ..
  "dab9fe6525d890210d151d86adb73615a865a54edcc0f01993c42566aef98ffb99e7afeabe000731" ..
  "48cbff086ddf285a7f9b6af1ebf78baf58627e1a149bba212cd16e2abd791e33d363eff5f0977996" ..
  "0ce2a38c344a6eed1a804aadb9cfa741907f30421d78c5de501f65edb3034d0737624ae5a48fa6e9" ..
  "957baf61700cff4e3a6c27934e31188ad49503536abca345088e049589c432e0f943aee7febf21b8" ..
  "6c3b8e3e336139d3364f6ffa464ee52ed60f6dcedc31422256963b0dca418fc016f50edf91e513af" ..
  "ef1955914b609f93565601c0364e3228ecb53939887e8175bac7a9a18531294bb344c470397bba52" ..
  "65d34954daf3cebdb4b81b3fa97511e2b422061193d6f6a7071582401c38434d7a13f18bbedc4ff5" ..
  "bc4097b116c524d259b97885e2f2ea2899170a5dc31155446f423357e7c6a9f9325928ee6e6f8794" ..
  "d0e4366228b03343565c31f7de89ea2730f5611484119414d873db391292ed4f7bd94e1d8e17debc" ..
  "c7d9f16864a76e94947ae053ee56e63cc8c93882f9475f5f3a9bf55ba91f81cad9a11fbb3d9808e4" ..
  "0fd22063edc29fcab3f256d8aca0b0b9b03031a8b4516e8435dd37d5871448afe9f6082b05542e4e" ..
  "ebfafa33d7254b599255abb50d532280b9ab4ce57f2d34f3693501d628297551c62c58f97dd949bf" ..
  "cd454f8f19c5126abbe83f4ecc2bdecbdc842b7e2819e230ba89142e007503b8a3bc941d0a5061cb" ..
  "e9f6760e32cd802109c7e552bc76492f852f54934da55cc98107fccf064fcf56098954d51fff6580" ..
  "23b70edb1955c4bfc330de426430f69d4715ed43e8a45c0aa8d7e4dab780a08d0572b974f03ce0bb" ..
  "b57d2e985e1419c7e8d9ecbe2cf3d73f2fe4b17170e5975011317ba87905e7907fbf21ec8a1f45ec" ..
  "1725cabfcb045b00964e915cd5e2b2073e2b8bcbf016d66dbe7444e39328a0acf85b2b4fbcde44b7" ..
  "49353fea39ba63b11dd01aafcd53486a1fca8a92fd719f85fc7c95d827357afa18a6a990c8b35ebd" ..
  "cccb7005c6b9c28d3bdbb92c43b17f26aa70b5b4f89695a2e94c39a54a98307fb7a0b174cff6f36e" ..
  "d4dba84729af48ad2e18bc1ad9704a682de0966daf2f8b1cb9c11d5b1e43a07e64972d68dee33360" ..
  "94628d38d0c20584dbc0d2b6ab90a559d2733c4335c6a72f7e75d99d94a70f4d6ced1983376fa72b" ..
  "97fcaacbf030bc247b77497b32503b128547eddfb81ccb9479999cdff70902cbcffe1939438e9b24" ..
  "829626e3892d95d792fae24291f2b3f163e22c147b9c3403c678b6d860284a1c5873888850659ae7" ..
  "0981dcd296a8736d9f65789a6509a4409ff38fed72e9052fe479ee5b9930578ce7f28ecd2d49eecd" ..
  "56c074a581ea17fe5544f7d774b14aef7b3f0195fc6f290f12153635b2c0cf577f5126dbba5e0ca7" ..
  "7a76956c3eafb4133d5774a11d31ab398a1b083821f40cb47b4a38e32537df62950113646d1d6e03" ..
  "4da8979a0041e8a93bc36e078f7515d75d0a12f27ad310d17f9d1a2e1ebe1327da3a361b1c5157b1" ..
  "dcdd7d20903d0c2536833336d068f707ce68341f79893389ab9090168dd05f3443954b3252dc25e5" ..
  "b438c2b67f98e5e910dcd78e3851a492dbc27ab5447822bf9b3cdb65f82ca382b67b7896167b4c84" ..
  "bfced1b0048eac50a9119b60369ffebd1fff7ac80904bf45ac12fb171817eee7af08da9177dda93d" ..
  "1b0cab936e65c744b559eb1d04e5e932c37b45b3f8d6f2bac3a9dc228caac9e9f3b8b6675a6507ff" ..
  "9fc477de4ed681da67378d8eccef96cb6dd856d94d259236a319ce15b0b4db31073973751f12dd5e" ..
  "8a8e849eb32781a5e1925c71285279f574c04bf1790c0efe4dda48153c94938a9d266d6a1cc0542c" ..
  "7440fb816508c4fe13328503df48229fd6bf7baee43cac404838d65f6ef6748f1e152328f3318dea" ..
  "8f8419a348f296bf72c8834a5957b511d7a023a73260b45c94ebc8abcfb56dae9fc10d0f989993e0" ..
  "de68a2355b93cae6a44cfe79ae538bbe9d1d84fcce37142551d2b1ab2ddfb6362fd7e4b9e72cd38c" ..
  "65ca5b96b7552210dd69a0d8ab3b546d604d51b25fbf70e273aa8a564fb7ac9e1a8c1e992b941148" ..
  "aac40a2703d9bea0764dbeae7fa4f3a61e99b96e70a9be8b2c5e9deb57ef47433a938fee32d29981" ..
  "26e6db8ffdf5adfe469356c504ec9f9dc8763c5b08d1908c3f6c6af859d800557f7cc39420a3a545" ..
  "9bfb227ebdf4c5ce89039d79d6fc5c5c8fe88b57305e2ab6a09e8c8c35ab96defa7e393983325753" ..
  "d6b6d0ecc617c699dfea21ea9e7557e3b67c1fa481680af8ca1e3785a9e724e51cfc8bed0d681639" ..
  "d18d8549d140caea4ed0fe7e9dc91335e4dbf0634473f5d21761f93a44d5aefe53898e4c3910da55" ..
  "734de8181f6ec39a2680b122baa28d97298af231c85bafab7983eed3740847d566c1a2a1a60cd889" ..
  "9e17e49642a3e4c1edb454e7badc080550b704cab602c3294cc317fb9cddd02366b4835d9eafea22" ..
  "219b97e26ffc81bd261e4e4c0a333a9d1fe2cca76517db90d7504dfa8816edbbb9571fa04dc089c8" ..
  "1ddc0325259b27decf3f4688801eb9aaf4f5d05c10cab24338b6525c21a42b0e36f60e2ba4fa6800" ..
  "eb3593803173e0ce9c4cd6257c5a3603af0c317d32adaa8a258e5a80c7204c4b8b889d624d44885d" ..
  "f4d14597e660f855d4347f66ec8941c3e699ed85b0dfb40d2472f6207c2d0484c2a1e7b5b459aeb5" ..
  "ab4f6451cc1d45ec63767572ae3d6174a59e0bd101731a28116d0016cb948f092cf9c8ca052f6e9f" ..
  "0b090a7560a968e3abeeddb2dde06ff158efc10b06a2068dc6e57a78fbd986e02eab8ca63ce802d7" ..
  "14a195640116f3367c0828dd624ec390d74bbe77e6116ac7804456af10f5fb53ebe9ea2adf4321c7" ..
  "03219a39ee587a3049787fef17af9924a1e9300cd85205485b45e522e4b1b4efb49c3b3995091a36" ..
  "d4490ad526f1443112a8f216af9418c2001f837cc73505241877b51e57a764d5a2853b80f17f58ee" ..
  "993e1de72d36d310b3598080ce64a656252f59cf0d9f04bbd23c8e176d1136001bda0492e7e4586e" ..
  "21e0bd5026c619bf3b097adaf088f94e8d14dedb30be846ef95cffa23af5f6f43871700761b3f743" ..
  "ca672b91e9e4fa1664c8e531bff53b55241260ed4ad1e87d106c09b972d2e8227fba195410e5ca30" ..
  "7884d9bc6cb569d80647dfedcd894a2963573ff03e2247744fc8e9560f91b1231db956e450275779" ..
  "b8d91274b9e9d4fba2ebee47e2fbfce1d9f1f30ccd97fb09efed53d75fd64e6b2e6d02c36017f67f" ..
  "a9aa4d20db084e9bb64be8d8b25396c170cb6af7c2d5bcf098f076a4f7a2322ebf84470805e69b5f" ..
  "94c3251f06f90cf33e003e616a6591e9b925a6cd0421aff361bdd1307c66e300bf8d5108e27e0d48" ..
  "240ab57a8b888b20fc87614baf287e07ef02cdd06ffdb432a1082c0466df6c0a8215e577001332c8" ..
  "d39bb9c3a48db6cf2738259634305c1461cf4f94c97df93d1b6baca2ae4e125b758f450c88572e0b" ..
  "959f587d507a8359b063e962e045f54d60e8ed72c0dff5d17b64978555326f9ffd080d236da814ba" ..
  "8c90fd9b083f4558106f72fe81e2c5907976033a39f7d952a4ec0132764ca04b733ea705fae4fa77" ..
  "b4d8f77bc3e561679e21f4f903b33fd99d765e419fb69f6dd30c088ba61ea5ef5d94337fbfaf7f5b" ..
  "1a4e4822eb4d7a596ffe73e81b637fb3ddf957bc36d8b9ca64d0e29eea8838b308dd9bdfd96b9f63" ..
  "087e79e5a57d1d13e328e230e3e2b3fb1c2559e30f0946be720bf5f26f4d2eaab0774d261cc609db" ..
  "443f64ec5a3711954112cf68649a260ed813f2fab7f5c5ca660d3257380841ee59ac2c7873f910a3" ..
  "e846963877671a1793b633abfa3469f8c0c0f5a60ef4cdcfcaf21ecd4377b28c57277707199b8175" ..
  "506c11b9d90e8b1dd83cc2687a19255f4a29c6465a314cd1ed2df21216235097b5635c95ff7296e2" ..
  "22af003ab672e81152e762596bf682359aeba33ac6ecc6b0944f6de09134dfb66c47bec883a7de39" ..
  "6ad047c430a12104a5b1cfdba0ab40677c45d833aff078625092ef950a16da0b9338e69c052b8e7b" ..
  "455a4b4cfe30e3f56b02e63195ad0cf86b17b224bad6bf27d1e0ccd25bb9c169de0c89a556b9ae70" ..
  "50065e535a213cf69c1169fa2777b87478edefd694af1eed6dc93d9526a50e68ee97f453f06791ed" ..
  "32ab0edb696703d33a6853c7e70757a731865ced6120f37d67fef95d926078901f2b1d1f15f6dc9c" ..
  "b69e38a8965c6b65aa9119ff184cccf4f43c732873f24c13fb4a3d794a9a80d23550c2321fd6109c" ..
  "371f77e76bb8417e6bfa9aae5ec05779cd04f3ff001a4778e3273522064480ca9f91508bffcfc14a" ..
  "049a7f41061a9e60fcb6be43a9f2fe9b08de8a1c7797da9b8f9887e6078735a1b5b4071dbfc73a66" ..
  "230e343dfba08d3343ed7f5a0fae657d3a88a0fbbcb05c6321874b8b4d2dbc4f1bdea12e35f6a8c9" ..
  "53c065c6c8e63528e34a1d250e7a8d6bd6b04d3b7651dd7e5e90277e7cb39e2d2c046f22062dc67d" ..
  "b10bb459132d0a263fa9ddfb67e2f1990e09b88e1914f7af10e8b35af3eeab379eedeca8e272b933" ..
  "d4c718bc4ae8ae5f81536d601170fc2091b534f885818a06ec8177f83f900978190e714fada5156e" ..
  "b592bf39b036496389c350c893ae7dc1ac042e70f8b383f2b49b52e587a1ee60fb152fe3ff26da89" ..
  "3e666e6f69ae2c153b544ebe544c19f9e805a1e290cf245624b33c9d7ed25117e74733427b72f0c1" ..
  "0a804d18b709747557e3306d881edb4f4ae7d6a36eb5dbcb2d8d5432157064c8d1e649de1e7f268b" ..
  "8a328a1cedfe552c07a3aec79624c7da84547ddc3e203c94990a98fd5071d2631a4ff12616eefc89" ..
  "f6f7fd143171420030c05b1ba332f41c8d2636b81555a78646c9feb55d120902ccec0a73b49c9921" ..
  "4e9d2827355fc49219ebb029435dcb0f4659d2b743848a2c963ef2c96b33be3174f85198b05a2e7d" ..
  "5a0f544dd2b1fb1803727073c2e134b1c7f6aa2de59aea61352787baa0d7c22f9853eab63b5e0b35" ..
  "abbdcdd7ed5c0860cf05daf5ac8d77b049cad48cebf4a71e7a4c10ec2158c4a6d9e92aa246bf719e" ..
  "13ae978d09fe5557730499af921549ff4e4b705b92903ba4ff577222c14f0a3a55b6344cf97aafae" ..
  "b862225b055b6960cac09afbddd2cdb4daf8e9829fe96b5fb5fdfc5d3132c498310cb380db6f7503" ..
  "e87fbb46217a360e2102ae466ebb1148f8549e1a3aa5e00d07a69afdcc42261ac4c118bfe78feaae" ..
  "f9f4892ed96bd4381af3dbe25d8f45daf5b4b0b0d2deeeb4962aceefa82e1c84046e3ecaaf453ce9" ..
  "f05d129681949a4c964781ce734b3c849c2ed44081ce5fbd522e23f3925e319e177e00f9fc32f791" ..
  "2bc60a63a6f3b3f2222bbfae61725606486289ddcc3d67807dc7785b8efdfc808af38731c02ba980" ..
  "1fab64ea29a2ddf7e4d9429322cd065a9da058c67844f20c24c0e332b70019b0233003b5a6cfe6ad" ..
  "d586bd01c5c217f65e5637885f29bc2b7eba726d8c94094b0a56a5f0bfe39272d79476a84ee20d06" ..
  "9e4c1269baa4bf3717efee45b0dee6401d95b0a5fcf90bc693cbe0b699c2585d65fa4f227a2b6d79" ..
  "d5f9e858292504d5c2b5a03f71471a6f59300222b4561e00ce2f8642ca0712dc7ca9723fbb2e8988" ..
  "2785338347f2ba08c61bb3a141e50e8c150f361dab9dec269f6a419d382595f464a53dc924fe7ac9" ..
  "142de49fff7a7c3d0c335248857fa9e70a9c32d5eae45305e6c42178c4bbb92e71f1ce2490d20b07" ..
  "f1bcc3d275afe51ae728e8c83c33407496fbf83a1288462481a1549fd6573da55fa7867caf35e149" ..
  "56986e2ef3ed091b917f1dd5f8886c61d20d8c88c8ffe65f31d71dce64b2c310f165b587df898190" ..
  "a57e6339dd2cf3a01ef6e6dbb1961ec970cc73d90bc26e24e21a6b35df0c3ad7003a93d8b2806962" ..
  "1c99ded33cb890a1cf3145de0add4289d0e4427a5514fb7277c621cc9fb3a48367a34dac4356550b" ..
  "f8d626aaaf278509"
)

local RandomHigh = {}
local RandomLow = {}
for i = 0, 780 do
  local hex = RANDOM_HEX:sub(i * 16 + 1, i * 16 + 16)
  RandomHigh[i] = tonumber(hex:sub(1, 8), 16)
  RandomLow[i] = tonumber(hex:sub(9, 16), 16)
end

local function xorRandom(high, low, index)
  return bxor(high, RandomHigh[index]), bxor(low, RandomLow[index])
end

--------------------------------------------------------------------------------
-- FEN parsing and Polyglot hash
-- Piece encoding: black pawn=0, white pawn=1, ..., black king=10, white king=11
-- Square: a1=0 .. h8=63
-- Castling: 768=WK, 769=WQ, 770=BK, 771=BQ
-- En passant file: 772+file, only if a pawn of the side to move can capture
-- Side to move: 780 if white
--------------------------------------------------------------------------------
local KIND = {
  p = 0, P = 0,
  n = 1, N = 1,
  b = 2, B = 2,
  r = 3, R = 3,
  q = 4, Q = 4,
  k = 5, K = 5,
}

local function parseBoard(placement)
  local board = {}
  local rank, file = 7, 0
  for i = 1, #placement do
    local c = placement:sub(i, i)
    if c == "/" then
      rank = rank - 1
      file = 0
    elseif c:match("%d") then
      file = file + tonumber(c)
    else
      local sq = file + rank * 8
      if sq >= 0 and sq <= 63 then
        board[sq] = c
      end
      file = file + 1
    end
  end
  return board
end

local function fourFields(fen)
  if not fen or fen == "" then return nil end
  local parts = {}
  for p in fen:gmatch("%S+") do
    parts[#parts + 1] = p
  end
  if #parts < 1 then return nil end
  return parts[1],
      (parts[2] == "b") and "b" or "w",
      parts[3] or "-",
      (parts[4] and parts[4] ~= "-") and parts[4] or nil
end

function Book.HashFen(fen)
  local placement, stm, castling, ep = fourFields(fen)
  if not placement then return nil end
  local board = parseBoard(placement)
  local high, low = 0, 0

  for sq = 0, 63 do
    local p = board[sq]
    if p then
      local kind = KIND[p]
      if kind then
        local color = (p == p:upper()) and 1 or 0
        local index = 64 * (2 * kind + color) + sq
        high, low = xorRandom(high, low, index)
      end
    end
  end

  if castling and castling ~= "-" then
    if castling:find("K", 1, true) then high, low = xorRandom(high, low, 768) end
    if castling:find("Q", 1, true) then high, low = xorRandom(high, low, 769) end
    if castling:find("k", 1, true) then high, low = xorRandom(high, low, 770) end
    if castling:find("q", 1, true) then high, low = xorRandom(high, low, 771) end
  end

  if ep and #ep >= 2 then
    local file = ep:byte(1) - ("a"):byte(1)
    local rank = tonumber(ep:sub(2, 2))
    if file and file >= 0 and file <= 7 and rank then
      local ready = false
      if stm == "w" and rank == 6 then
        if file > 0 and board[(file - 1) + 4 * 8] == "P" then ready = true end
        if file < 7 and board[(file + 1) + 4 * 8] == "P" then ready = true end
      elseif stm == "b" and rank == 3 then
        if file > 0 and board[(file - 1) + 3 * 8] == "p" then ready = true end
        if file < 7 and board[(file + 1) + 3 * 8] == "p" then ready = true end
      end
      if ready then
        high, low = xorRandom(high, low, 772 + file)
      end
    end
  end

  if stm ~= "b" then
    high, low = xorRandom(high, low, 780)
  end

  return keyHex(high, low)
end

--- Ply count from FEN (0 at the start position). Uses fullmove number and side to move.
function Book.PlyFromFen(fen)
  if not fen or fen == "" then return nil end
  local parts = {}
  for p in fen:gmatch("%S+") do
    parts[#parts + 1] = p
  end
  if #parts < 1 then return nil end
  local stm = (parts[2] == "b") and "b" or "w"
  local full = tonumber(parts[6]) or 1
  if full < 1 then full = 1 end
  local ply = (full - 1) * 2
  if stm == "b" then
    ply = ply + 1
  end
  return ply
end

local function normalizeElo(book)
  if not book then return nil end
  local minE, maxE
  if type(book.elo) == "table" then
    minE, maxE = tonumber(book.elo[1]), tonumber(book.elo[2])
  elseif type(book.elo) == "number" then
    minE, maxE = book.elo, book.elo
  else
    minE = tonumber(book.minElo)
    maxE = tonumber(book.maxElo)
  end
  if not minE and not maxE then return nil end
  minE = minE or maxE
  maxE = maxE or minE
  if minE > maxE then
    minE, maxE = maxE, minE
  end
  return { minE, maxE }
end

local function bookInfo(b)
  local info = {
    id = b.id,
    name = b.name,
    description = b.description or "",
  }
  if b.elo then
    info.elo = { b.elo[1], b.elo[2] }
    info.minElo = b.elo[1]
    info.maxElo = b.elo[2]
  end
  return info
end

--------------------------------------------------------------------------------
-- Book registry
--------------------------------------------------------------------------------
local function addMove(list, move, weight)
  weight = tonumber(weight) or 1
  for i = 1, #list do
    if list[i].move == move then
      list[i].weight = list[i].weight + weight
      return
    end
  end
  list[#list + 1] = { move = move, weight = weight }
end

local function mergeEntries(dest, key, moves)
  if not key or not moves then return end
  local list = dest[key]
  if not list then
    list = {}
    dest[key] = list
  end
  for i = 1, #moves do
    local m = moves[i]
    if type(m) == "table" and type(m.move) == "string" and m.move ~= "" then
      addMove(list, m.move, m.weight)
    elseif type(m) == "string" and m ~= "" then
      addMove(list, m, 1)
    end
  end
end

function Book:Register(book)
  if not book or type(book.id) ~= "string" or book.id == "" then
    return false
  end
  if type(book.name) ~= "string" or book.name == "" then
    return false
  end

  local entries = {}
  if type(book.entries) == "table" then
    for key, moves in pairs(book.entries) do
      if type(key) == "string" then
        mergeEntries(entries, key:lower(), moves)
      end
    end
  end
  if type(book.positions) == "table" then
    for fen, moves in pairs(book.positions) do
      local key = Book.HashFen(fen)
      if key then
        mergeEntries(entries, key, moves)
      end
    end
  end

  self.books[book.id] = {
    id = book.id,
    name = book.name,
    description = book.description or "",
    elo = normalizeElo(book),
    entries = entries,
  }
  return true
end

function Book:GetBook(id)
  if not id then return nil end
  return self.books[id]
end

function Book:GetBookList()
  local list = {}
  for _, b in pairs(self.books) do
    list[#list + 1] = bookInfo(b)
  end
  table.sort(list, function(a, c)
    if a.name == c.name then return a.id < c.id end
    return a.name < c.name
  end)
  return list
end

--- Books whose ELO range is closest to elo (all in-range first, else nearest).
function Book:GetBooksForElo(elo)
  elo = tonumber(elo)
  if elo == nil then return {} end
  local scored = {}
  for _, b in pairs(self.books) do
    if b.elo then
      local minE, maxE = b.elo[1], b.elo[2]
      local dist = 0
      if elo < minE then
        dist = minE - elo
      elseif elo > maxE then
        dist = elo - maxE
      end
      scored[#scored + 1] = { book = b, dist = dist }
    end
  end
  if #scored == 0 then return {} end
  local best = scored[1].dist
  for i = 2, #scored do
    if scored[i].dist < best then
      best = scored[i].dist
    end
  end
  local list = {}
  for i = 1, #scored do
    if scored[i].dist == best then
      list[#list + 1] = bookInfo(scored[i].book)
    end
  end
  table.sort(list, function(a, c)
    local aMax = a.maxElo or 0
    local cMax = c.maxElo or 0
    if aMax == cMax then return a.id < c.id end
    return aMax > cMax
  end)
  return list
end

local function normalizeBookIds(bookIds)
  if bookIds == nil then return nil end
  if type(bookIds) == "string" then
    return { bookIds }
  end
  return bookIds
end

function Book:Lookup(fen, bookIds, depth)
  depth = tonumber(depth)
  if depth ~= nil then
    local ply = Book.PlyFromFen(fen)
    if ply == nil or ply >= depth then
      return {}
    end
  end
  local key = Book.HashFen(fen)
  if not key then return {} end
  local ids = normalizeBookIds(bookIds)
  local results = {}
  if ids then
    for i = 1, #ids do
      local b = self.books[ids[i]]
      local moves = b and b.entries[key]
      if moves then
        for j = 1, #moves do
          local m = moves[j]
          results[#results + 1] = { move = m.move, weight = m.weight, bookId = b.id }
        end
      end
    end
  else
    for id, b in pairs(self.books) do
      local moves = b.entries[key]
      if moves then
        for j = 1, #moves do
          local m = moves[j]
          results[#results + 1] = { move = m.move, weight = m.weight, bookId = id }
        end
      end
    end
  end
  return results
end

--- Weighted random book move, honoring optional ply depth. No legality check.
function Book:SelectMove(fen, bookIds, depth)
  local candidates = self:Lookup(fen, bookIds, depth)
  local total = 0
  local usable = {}
  for i = 1, #candidates do
    local w = tonumber(candidates[i].weight) or 0
    if w > 0 then
      usable[#usable + 1] = candidates[i]
      total = total + w
    end
  end
  if total <= 0 or #usable == 0 then
    return nil
  end
  local pick = math.random(1, total)
  local acc = 0
  for i = 1, #usable do
    acc = acc + (tonumber(usable[i].weight) or 0)
    if pick <= acc then
      return usable[i]
    end
  end
  return usable[#usable]
end

return Book
