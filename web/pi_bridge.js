(function () {
  'use strict';

  const PiBridge = {
    isAvailable() {
      return typeof window.Pi !== 'undefined';
    },

    async initialize() {
      if (!this.isAvailable()) {
        return {
          success: false,
          message: 'Pi SDK is not loaded'
        };
      }

      try {
        await window.Pi.init({
          version: '2.0',
          sandbox: true
        });

        return {
          success: true,
          message: 'Pi SDK initialized'
        };
      } catch (error) {
        return {
          success: false,
          message: String(error)
        };
      }
    }
  };

  window.UBarberPiBridge = PiBridge;
})();