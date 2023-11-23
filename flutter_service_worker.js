'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"manifest.json": "60cf0e8a29d91fc890f252903819f5ae",
"flutter.js": "7d69e653079438abfbb24b82a655b0a4",
"version.json": "43404ef1c0265c5707b42cb07d6c068f",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"index.html": "ab7257ae59b0bac55b5bc1ebcf8f0d19",
"/": "ab7257ae59b0bac55b5bc1ebcf8f0d19",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"assets/FontManifest.json": "eda3f246271a3a4de7fa1c70eb5fc7a7",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "89ed8f4e49bcdfc0b5bfc9b24591e347",
"assets/NOTICES": "e4e3f6aec45b66488ea537e2e027c96a",
"assets/AssetManifest.json": "95cd08e5ee33f762b2f308acdc82600f",
"assets/AssetManifest.bin.json": "a2345c200688962fbccf6e94440166a4",
"assets/shaders/ink_sparkle.frag": "4096b5150bac93c41cbc9b45276bd90f",
"assets/assets/svg/back.svg": "78af4432c32978ccb5ecb0ca18a88f1b",
"assets/assets/svg/spasticity.svg": "9507b915d80d2980d0ed00c7d9a2e7d9",
"assets/assets/svg/intermittentNeuroPathic.svg": "bf8e68696aa8f929e40f55623a415562",
"assets/assets/svg/flame.svg": "9965b037e8c0faeff50d77053c14b696",
"assets/assets/svg/wheelchair.svg": "62f1fb4f6c05a14ef57b6d5b2257506e",
"assets/assets/svg/allodynia.svg": "1cdd8727e54d83bb81009f6cd7ffa660",
"assets/assets/svg/toilet.svg": "e4f5fd01e00a2b01352c03f5d8e251d4",
"assets/assets/svg/neuropathic.svg": "aa50c328bccafa9e1d5bb2c9ff8101db",
"assets/assets/svg/goal_done.svg": "262c608bdb514fee829b031114457991",
"assets/assets/svg/empty_state.svg": "dde4739d2edae1639b5914423d9fc3f6",
"assets/assets/svg/person.svg": "312ee8ae1cdc3b375ecd477f98fb95af",
"assets/assets/svg/exercise.svg": "1c8990a56bf4fa2cee62dca2d7248e84",
"assets/assets/svg/hand.svg": "b5e5831de2ea4932bdae0bc61cddbfbd",
"assets/assets/svg/shoulderJoint.svg": "751c1df53ee547739a38e6aa3bc99760",
"assets/assets/svg/elbow.svg": "2291853d3755d869e900f19d2a003cbd",
"assets/assets/svg/scapula.svg": "8ea55719af7d97ebfbf8eee3451df3e5",
"assets/assets/svg/alarm.svg": "91bb66291a4c3e002c76716afbb4d50a",
"assets/assets/svg/neck.svg": "8b2e0477b4d9553742a2c426f2d6c08a",
"assets/assets/svg/set_goal.svg": "b0ce64db60182b2b79655f2f1b160672",
"assets/assets/images/ryggmarg_logo.png": "de84e84b5408560623f7ddb99ab1d046",
"assets/assets/images/pressure_release_right.jpeg": "8616fe635ec4663f8fed52c83fb70ccf",
"assets/assets/images/pressure_release_left.jpeg": "43c3e85e624378380c0be73664c2c8f5",
"assets/assets/images/fitbit.png": "d9b04dc58e5bdd0bf7787fd35a14bb9c",
"assets/assets/images/pressure_release_forward.jpeg": "0bb98a11f57ee85256d8debfbcb771ca",
"assets/assets/images/right.png": "a3c514c328567b033b13e66f1dfacf8b",
"assets/assets/images/pressure_release_lying.jpeg": "b62a778e1344f331df15f463ecfbe7be",
"assets/assets/images/pressure_ulcer_map.png": "b9bf41de4ec5649bd4ac3690b4532e8a",
"assets/assets/licenses/icon_license.txt": "023eedd873ff348626a8757161290164",
"assets/assets/fonts/Manrope-Bold.ttf": "2af19b388ce4f0e3617fed61faea284e",
"assets/assets/fonts/Manrope-SemiBold.ttf": "be79203f7047b78f1374f8658fe01208",
"assets/assets/fonts/Manrope-Medium.ttf": "36bd05140475db525b9617f601c201a6",
"assets/assets/fonts/Manrope-Regular.ttf": "d132ed5224d61c7c2c71e44cd2750999",
"assets/assets/fonts/Manrope-Light.ttf": "d0704eb4a339c1895bf5d7a153a25c84",
"assets/assets/fonts/Manrope-ExtraLight.ttf": "fc80ad19afcbea34e8dbdedb9e60bd45",
"assets/assets/fonts/Manrope-ExtraBold.ttf": "5167c303a88f05722db3b07c584cbb40",
"assets/AssetManifest.bin": "67338a8cfad10d5fd1e57294e8dba146",
"assets/fonts/MaterialIcons-Regular.otf": "6343883c0c96e8bcb682a5fa16dd89b6",
"canvaskit/skwasm.wasm": "4124c42a73efa7eb886d3400a1ed7a06",
"canvaskit/canvaskit.js": "eb8797020acdbdf96a12fb0405582c1b",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/skwasm.js": "87063acf45c5e1ab9565dcf06b0c18b8",
"canvaskit/canvaskit.wasm": "64edb91684bdb3b879812ba2e48dd487",
"canvaskit/chromium/canvaskit.js": "0ae8bbcc58155679458a0f7a00f66873",
"canvaskit/chromium/canvaskit.wasm": "f87e541501c96012c252942b6b75d1ea",
"main.dart.js": "1bf9424c4a2a16b350b7fa19252eeb99"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.json",
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
