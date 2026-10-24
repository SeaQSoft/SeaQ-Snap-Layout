import QtQuick
import org.kde.kwin
import "../code/keys.js" as K

// Talks to KDE's global shortcut service (kglobalaccel) over D-Bus, the same
// way System Settings → Shortcuts does. ShortcutHandler can only register a
// default key once, so changing a key afterwards has to go through here.
//
// D-Bus needs real string and int lists ("as", "ai"). Plain JS arrays would be
// sent as variant lists and rejected, so the arguments are passed through
// the typed list properties below.
QtObject {
    id: svc

    // what the kglobalaccel action ids of a KWin script look like
    readonly property string component: "kwin"
    readonly property string componentName: "KWin"

    property list<string> idList
    property list<int> keyList
    property int keyCode: 0

    property var jobs: []
    property var current: null
    property bool busy: current !== null

    // actionId -> array of key codes (first key of every assigned sequence)
    property var keys: ({})
    property int revision: 0          // bumps whenever keys change, for bindings
    property bool available: true     // false once kglobalaccel didn't answer

    signal applied(string action, bool ok, int requested)
    signal conflict(string action, int code, var owners)

    property DBusCall call: DBusCall {
        service: "org.kde.kglobalaccel"
        path: "/kglobalaccel"
        dbusInterface: "org.kde.KGlobalAccel"
        onFinished: (reply) => svc.done(true, reply)
        onFailed: svc.done(false, [])
    }

    function actionIdFor(id, text) { return [component, id, componentName, text]; }

    function enqueue(job) {
        const list = jobs.slice();
        list.push(job);
        jobs = list;
        if (!current) next();
    }

    function next() {
        if (jobs.length === 0) { current = null; return; }
        const list = jobs.slice();
        current = list.shift();
        jobs = list;
        idList = current.id || [];
        keyList = current.keys || [];
        keyCode = current.code || 0;
        call.method = current.method;
        if (current.method === "setForeignShortcut") call.arguments = [svc.idList, svc.keyList];
        else if (current.method === "getGlobalShortcutsByKey") call.arguments = [svc.keyCode];
        else call.arguments = [svc.idList];
        call.call();
    }

    function done(ok, reply) {
        const job = current;
        current = null;
        try { if (job && job.cb) job.cb(ok, reply || []); } catch (e) { console.warn("[kdesnaplayout] shortcut job:", e); }
        // the callback may have started the next job itself (enqueue on an idle queue)
        if (!current) next();
    }

    // reply of "shortcut": a list of ints
    function codesOf(reply) {
        const out = [];
        const flat = function (v) {
            if (Array.isArray(v)) { for (let i = 0; i < v.length; i++) flat(v[i]); }
            else if (typeof v === "number" && v) out.push(v);
            else if (v && typeof v === "object" && v.length !== undefined) { for (let i = 0; i < v.length; i++) flat(v[i]); }
        };
        flat(reply && reply.length ? reply[0] : []);
        return out;
    }

    function setKeys(action, codes) {
        const k = Object.assign({}, keys);
        k[action] = codes;
        keys = k;
        revision++;
    }

    // ---------------------------------------------------------------- API
    function read(action, text) {
        enqueue({ method: "shortcut", id: actionIdFor(action, text), cb: function (ok, reply) {
            if (!ok) { svc.available = false; return; }
            svc.available = true;
            svc.setKeys(action, svc.codesOf(reply));
        } });
    }

    function readAll(actions, textOf) {
        for (let i = 0; i < actions.length; i++) read(actions[i].id, textOf(actions[i]));
    }

    // code 0 removes the shortcut
    function assign(action, text, code) {
        enqueue({ method: "setForeignShortcut", id: actionIdFor(action, text), keys: code ? [code] : [], cb: function (ok) {
            if (!ok) { svc.available = false; svc.applied(action, false, code); return; }
            // read back: kglobalaccel silently drops a key that is already taken
            svc.enqueue({ method: "shortcut", id: svc.actionIdFor(action, text), cb: function (ok2, reply) {
                const codes = ok2 ? svc.codesOf(reply) : [];
                svc.setKeys(action, codes);
                const good = code === 0 ? codes.length === 0 : codes.indexOf(code) >= 0;
                svc.applied(action, good, code);
                if (!good && code) svc.findOwners(action, code);
            } });
        } });
    }

    // who else uses this key? owners: [{ id: [...4 strings], name, app, keys: [...] }]
    function findOwners(action, code) {
        enqueue({ method: "getGlobalShortcutsByKey", code: code, cb: function (ok, reply) {
            const owners = [];
            const list = ok && reply.length ? reply[0] : [];
            for (let i = 0; i < (list ? list.length : 0); i++) {
                const s = list[i];
                if (!s || s.length < 7) continue;
                if (s[2] === svc.component && s[0] === action) continue;
                owners.push({ id: [s[2], s[0], s[3], s[1]], name: s[1], app: s[3], keys: svc.codesOf([s[6]]) });
            }
            svc.conflict(action, code, owners);
        } });
    }

    // Takes a key away from other actions, then gives it to ours.
    function reassign(action, text, code, owners) {
        for (let i = 0; i < owners.length; i++) {
            const o = owners[i];
            const rest = o.keys.filter(function (k) { return k !== code; });
            enqueue({ method: "setForeignShortcut", id: o.id, keys: rest, cb: function () {} });
        }
        assign(action, text, code);
    }
}
