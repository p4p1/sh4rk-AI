const HOST = "com.web.platform";
const RECONNECT_MS = 5000;

const api = globalThis.browser ?? globalThis.chrome;

let port = null;

function connect() {
  if (port) return;
  port = api.runtime.connectNative(HOST);
  port.onDisconnect.addListener(() => {
    port = null;
    setTimeout(connect, RECONNECT_MS);
  });
}

api.runtime.onStartup.addListener(connect);
api.runtime.onInstalled.addListener(connect);
api.alarms.create("wph", { periodInMinutes: 1 });
api.alarms.onAlarm.addListener(connect);
connect();
