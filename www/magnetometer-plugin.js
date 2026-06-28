// magnetometer-plugin.js
// Pont JavaScript vers le plugin Swift MagnetometerPlugin
// À placer dans www/ à côté de index.html

// Enregistrer le plugin immédiatement via Capacitor.registerPlugin
// qui est disponible dès que capacitor.js est chargé
(function() {
  function initPlugin() {
    if (window.Capacitor && typeof Capacitor.registerPlugin === 'function') {
      window.MagnetometerPlugin = Capacitor.registerPlugin('Magnetometer', {
        web: () => Promise.reject(new Error('Magnetometer plugin: iOS only')),
      });
    } else {
      // Réessayer dans 100ms si Capacitor n'est pas encore prêt
      setTimeout(initPlugin, 100);
    }
  }
  initPlugin();
})();
