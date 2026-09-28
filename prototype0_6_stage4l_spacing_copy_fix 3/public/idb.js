const DB_NAME='learnly-prototype06-stage4l';
const DB_VERSION=1;
const STORE='kv';
function openDB(){return new Promise((resolve,reject)=>{const r=indexedDB.open(DB_NAME,DB_VERSION);r.onupgradeneeded=()=>{const db=r.result;if(!db.objectStoreNames.contains(STORE))db.createObjectStore(STORE);};r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});}
async function idbSet(key,value){const db=await openDB();return new Promise((resolve,reject)=>{const tx=db.transaction(STORE,'readwrite');tx.objectStore(STORE).put(value,key);tx.oncomplete=()=>resolve();tx.onerror=()=>reject(tx.error);});}
async function idbGet(key){const db=await openDB();return new Promise((resolve,reject)=>{const tx=db.transaction(STORE,'readonly');const r=tx.objectStore(STORE).get(key);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});}
async function idbDel(key){const db=await openDB();return new Promise((resolve,reject)=>{const tx=db.transaction(STORE,'readwrite');tx.objectStore(STORE).delete(key);tx.oncomplete=()=>resolve();tx.onerror=()=>reject(tx.error);});}
async function queueSync(item){const q=(await idbGet('syncQueue'))||[];q.push({...item,queue_id:crypto.randomUUID(),queued_at:new Date().toISOString()});await idbSet('syncQueue',q);return q.length;}
async function flushSyncQueue(){if(!navigator.onLine)return {synced:0,pending:((await idbGet('syncQueue'))||[]).length};const q=(await idbGet('syncQueue'))||[];const remaining=[];let synced=0;for(const item of q){try{const r=await fetch(item.url,{...item.options,headers:{'Content-Type':'application/json',...(item.options?.headers||{})}});if(!r.ok)throw new Error('sync failed');synced++;}catch(e){remaining.push(item);}}await idbSet('syncQueue',remaining);return {synced,pending:remaining.length};}
window.localDB={get:idbGet,set:idbSet,del:idbDel,queue:queueSync,flush:flushSyncQueue};
