'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/assets/face_wireframe.png": "fc5b3732d5683984380adbc3cf87de40",
"assets/assets/google_logo.png": "e9612850a6cb55eb547266043e1eef86",
"assets/assets/json/personal_care.json": "08b2ca068ff1b8544c289c0ea62eae23",
"assets/assets/json/skin_analysis.json": "ab186949e3c9fec62d92950001b1ec9f",
"assets/assets/json/dermlogist.json": "069c6053f2372b0efc78c3a2603c39ae",
"assets/assets/logo.png": "794040fa08e712b17b4fe48df3178f8a",
"assets/NOTICES": "578ba6689061818de663d12263208fd2",
"assets/fonts/MaterialIcons-Regular.otf": "beeedb58be7d8d6a8a4f1f25381ea551",
"assets/AssetManifest.bin": "9d05b38d836a56e64649490dbe646153",
"assets/AssetManifest.bin.json": "a190eb23066b81828f0f9330e842850e",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/AssetManifest.json": "16e5623cc68d8443d0af7a660ca6ce9e",
"main.dart.js": "e50ee0d583b520a8d4c4b1b40977188c",
"flutter_bootstrap.js": "20bacd0c8f4835430b0ffc0aead60a50",
"manifest.json": "f2a58b029c66761d2ed65047730efad9",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"index.html": "e57a589b3e12b32100ce47fd944a4b54",
"/": "e57a589b3e12b32100ce47fd944a4b54",
"models/face-api.js-models/age_gender_model/age_gender_model-shard1": "c34648b1f6dcf740eedef0473f13f4e1",
"models/face-api.js-models/age_gender_model/age_gender_model-weights_manifest.json": "d443abfd550a910c026d40cad6ea6000",
"models/face-api.js-models/proto/ssd_mobilenet_face_optimized_v2.pbtxt": "cdb7a7357274b327fcf40eef5d102317",
"models/face-api.js-models/README.md": "565dfc42d88136be1609b481fd14b45a",
"models/face-api.js-models/face_expression/face_expression_model-shard1": "33ec63fec9fc41801930d44f4f4ea8f0",
"models/face-api.js-models/face_expression/face_expression_model-weights_manifest.json": "1eee5a2eea5ea5652904a2af88333dc1",
"models/face-api.js-models/uncompressed/ssd_mobilenetv1.weights": "f17fccdc47e044537f269e3586635f55",
"models/face-api.js-models/uncompressed/tiny_yolov2_separable_conv_model.weights": "29e4f02dd8847933f80b57b805bdd8de",
"models/face-api.js-models/uncompressed/tiny_face_detector_model.weights": "93127487a737311625b8f17799c01111",
"models/face-api.js-models/uncompressed/tiny_yolov2_model.weights": "835cb5b00ca8b37530fff2223c1678cc",
"models/face-api.js-models/uncompressed/face_expression_model.weights": "0ad0d8bdc486d862eeca0d274be609ff",
"models/face-api.js-models/uncompressed/face_landmark_68_model.weights": "4fe4ba7d7f18bdd7e2e4359ee7e435f2",
"models/face-api.js-models/uncompressed/face_landmark_68_tiny_model.weights": "6ba67178280f05146ac7fd3284759170",
"models/face-api.js-models/uncompressed/face_recognition_model.weights": "c157f67a5ce5f4ec90786b2ce6b11708",
"models/face-api.js-models/uncompressed/mtcnn_model.weights": "846e8dd4e6a7ed12a2c749324adf0e11",
"models/face-api.js-models/uncompressed/age_gender_model.weights": "570f1370c6a4b3700208c6de3f54556b",
"models/face-api.js-models/tiny_yolov2/tiny_yolov2_model-shard1": "e1e1b2d1d32ec602c32d9e92d43ad856",
"models/face-api.js-models/tiny_yolov2/tiny_yolov2_model-shard2": "d754ce0c7b1de5840cffb9b82fdf7393",
"models/face-api.js-models/tiny_yolov2/tiny_yolov2_model-weights_manifest.json": "eb48eddf6b17b3eb17590f97dcd275ee",
"models/face-api.js-models/tiny_yolov2/tiny_yolov2_model-shard3": "77f8697b427e1fd1fdfcf6a3b1e63432",
"models/face-api.js-models/tiny_yolov2/tiny_yolov2_model-shard4": "ac8c07199789f2c6dccae564029d83b3",
"models/face-api.js-models/tiny_face_detector/tiny_face_detector_model-weights_manifest.json": "5bab50532388f5da9b4cd85b15adc11c",
"models/face-api.js-models/tiny_face_detector/tiny_face_detector_model-shard1": "2e48b20953b0c59df47459d0319843a0",
"models/face-api.js-models/face_recognition/face_recognition_model-shard2": "f2091ed03625f6e164a637c2326691c1",
"models/face-api.js-models/face_recognition/face_recognition_model-shard1": "cb6f0f62e7598d70acf76483185a962b",
"models/face-api.js-models/face_recognition/face_recognition_model-weights_manifest.json": "6ecdaf3ea10d4fd3792e485f971e8b96",
"models/face-api.js-models/mtcnn/mtcnn_model-weights_manifest.json": "781bd744a5399d7cb0516d2a59a7c1c0",
"models/face-api.js-models/mtcnn/mtcnn_model-shard1": "846e8dd4e6a7ed12a2c749324adf0e11",
"models/face-api.js-models/ssd_mobilenetv1/ssd_mobilenetv1_model-shard1": "37ef238973ea93daac91f1914478c40b",
"models/face-api.js-models/ssd_mobilenetv1/ssd_mobilenetv1_model-weights_manifest.json": "cd2d65ec62107ba72b8b8d5047011647",
"models/face-api.js-models/ssd_mobilenetv1/ssd_mobilenetv1_model-shard2": "b6d5e81e2506145360be5c4278067080",
"models/face-api.js-models/tiny_yolov2_separable_conv/tiny_yolov2_separable_conv_model-shard1": "854aa834317e8851701eb13c4a906d7c",
"models/face-api.js-models/tiny_yolov2_separable_conv/tiny_yolov2_separable_conv_model-weights_manifest.json": "65c79f743958215cb78b796f2f6fd005",
"models/face-api.js-models/face_landmark_68/face_landmark_68_model-shard1": "124304f06e07fcf928290ff776e96141",
"models/face-api.js-models/face_landmark_68/face_landmark_68_model-weights_manifest.json": "1d4029763003335bc6921aadeb58706a",
"models/face-api.js-models/.git/packed-refs": "2526510d303bc5bd32c0bef34c37930a",
"models/face-api.js-models/.git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
"models/face-api.js-models/.git/refs/heads/master": "3066651658865ba92e1cb7d0efe3686f",
"models/face-api.js-models/.git/refs/remotes/origin/HEAD": "73a00957034783b7b5c8294c54cd3e12",
"models/face-api.js-models/.git/objects/pack/pack-4432239098f65e23beae8a9d0b4c23f106289f3c.idx": "511b72a8e980fb5ad5a72e14d8104caf",
"models/face-api.js-models/.git/objects/pack/pack-4432239098f65e23beae8a9d0b4c23f106289f3c.rev": "2017e0efb7bbac9d6855655b8390cf16",
"models/face-api.js-models/.git/objects/pack/pack-4432239098f65e23beae8a9d0b4c23f106289f3c.pack": "123a4fb7a29758228aa872705cb5999a",
"models/face-api.js-models/.git/HEAD": "4cf2d64e44205fe628ddd534e1151b58",
"models/face-api.js-models/.git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
"models/face-api.js-models/.git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
"models/face-api.js-models/.git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
"models/face-api.js-models/.git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
"models/face-api.js-models/.git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
"models/face-api.js-models/.git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
"models/face-api.js-models/.git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
"models/face-api.js-models/.git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
"models/face-api.js-models/.git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
"models/face-api.js-models/.git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
"models/face-api.js-models/.git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
"models/face-api.js-models/.git/hooks/pre-commit.sample": "305eadbbcd6f6d2567e033ad12aabbc4",
"models/face-api.js-models/.git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
"models/face-api.js-models/.git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
"models/face-api.js-models/.git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
"models/face-api.js-models/.git/logs/refs/heads/master": "78716f38c07bab32614b5f0dbfe7fa75",
"models/face-api.js-models/.git/logs/refs/remotes/origin/HEAD": "78716f38c07bab32614b5f0dbfe7fa75",
"models/face-api.js-models/.git/logs/HEAD": "78716f38c07bab32614b5f0dbfe7fa75",
"models/face-api.js-models/.git/index": "806203696ae3f9652f2f969720bc33b9",
"models/face-api.js-models/.git/config": "2f8111e720fad32916f7405a1d9132a7",
"models/face-api.js-models/face_landmark_68_tiny/face_landmark_68_tiny_model-weights_manifest.json": "29ea9c5c0e59a3069f8999b4ba1bd173",
"models/face-api.js-models/face_landmark_68_tiny/face_landmark_68_tiny_model-shard1": "47047fee26557b55d985952bdfc6cba1",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "0eb0e7fb6477f602ca787c24df12789b",
"icons/Icon-maskable-512.png": "09678b16b65430b899a30d386e7bdb3b",
"icons/Icon-512.png": "09678b16b65430b899a30d386e7bdb3b",
"icons/Icon-192.png": "22d63f5eaa962cb63cd8a9573e5c8bf3",
"icons/Icon-maskable-192.png": "22d63f5eaa962cb63cd8a9573e5c8bf3",
"version.json": "ab7e1ecdfd7126aeb87cc1934045be2a"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
