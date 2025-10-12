// web/face_detect.js

// Detect face bounding box using the browser FaceDetector API
// Falls back to a centered region if not supported.
window.detectFaceBBox = async function(imageUrl) {
  return new Promise(async (resolve) => {
    try {
      const img = new Image();
      img.crossOrigin = 'anonymous';
      img.onload = async () => {
        const imageW = img.naturalWidth || img.width;
        const imageH = img.naturalHeight || img.height;

        // If browser supports FaceDetector
        if ('FaceDetector' in window) {
          try {
            const fd = new window.FaceDetector({ fastMode: true });
            const bmp = await createImageBitmap(img);
            const faces = await fd.detect(bmp);
            if (faces && faces.length > 0) {
              const bb = faces[0].boundingBox;
              const pad = Math.round(Math.min(imageW, imageH) * 0.03); // small margin
              const x = Math.max(0, bb.x - pad);
              const y = Math.max(0, bb.y - pad);
              const w = Math.min(imageW - x, bb.width + 2 * pad);
              const h = Math.min(imageH - y, bb.height + 2 * pad);

              resolve({ x, y, width: w, height: h, imageW, imageH });
              return;
            }
          } catch (e) {
            console.warn("FaceDetector failed:", e);
          }
        }

        // Fallback: centered rectangle
        const w = Math.round(imageW * 0.6);
        const h = Math.round(imageH * 0.7);
        const x = Math.round((imageW - w) / 2);
        const y = Math.round((imageH - h) / 5);
        resolve({ x, y, width: w, height: h, imageW, imageH });
      };

      img.onerror = () => {
        console.error("Image failed to load:", imageUrl);
        resolve(null);
      };
      img.src = imageUrl;
    } catch (err) {
      console.error("detectFaceBBox error:", err);
      resolve(null);
    }
  });
};
