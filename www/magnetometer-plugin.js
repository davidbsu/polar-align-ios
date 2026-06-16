// magnetometer-plugin.js
// Pont JavaScript vers le plugin Swift MagnetometerPlugin
// À placer dans www/ à côté de index.html

const MagnetometerPlugin = Capacitor.registerPlugin('Magnetometer', {
  // Pas d'implémentation web — uniquement iOS natif
  web: () => Promise.reject(new Error('Magnetometer plugin: iOS only')),
});

window.MagnetometerPlugin = MagnetometerPlugin;
