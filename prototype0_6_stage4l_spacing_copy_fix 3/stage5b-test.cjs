const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
const path=require('node:path');
const source=fs.readFileSync(path.join(__dirname,'public/app.js'),'utf8').split('(async()=>{try{await localDB.flush();await loadHome()}')[0];
function fixture(){
  const app={innerHTML:'original card'},content={scrollTop:180},body={style:{cssText:'color: red'},append(d){this.dialog=d}};
  const focus={isConnected:true,focus(){this.restored=true}};
  const question={value:'Why does audience change detail?'},answer={textContent:''};
  let resolve;
  const context=vm.createContext({crypto:require('node:crypto'),console,localDB:{queue:async()=>{}},navigator:{onLine:true},window:{scrollX:0,scrollY:740,addEventListener(){},scrollTo(x,y){this.scrollX=x;this.scrollY=y}},document:{body,activeElement:focus,getElementById(id){return id==='app'?app:id==='contextQuestion'?question:id==='contextAnswer'?answer:null},querySelector(){return content},createElement(){return {innerHTML:'',events:{},setAttribute(){},showModal(){this.open=true},close(){this.open=false},remove(){body.dialog=null},addEventListener(k,v){this.events[k]=v},querySelector(){return {focus(){}}},getBoundingClientRect(){return {left:0,right:390,top:250,bottom:844}}}}}});
  vm.runInContext(source,context);
  const run=s=>vm.runInContext(s,context);
  run("currentActivity={activity_instance_id:'a',activity_type:'reading',content:{body:'The audience affects how much detail a writer provides.'}};panelIndex=4;qFeedback={correct:false};writingText='saved draft';reflectionState.responses={p:'saved reflection'}");
  context.fetch=()=>new Promise(r=>{resolve=r});
  return {run,app,content,body,focus,question,answer,context,reply(value){resolve({ok:true,json:async()=>value})}};
}
test('sheet dismissal preserves card DOM, response state, focus and both scroll positions',()=>{
  for(const method of ['close','escape','outside']){
    const f=fixture();f.run('showWhyThisMatters()');const dialog=f.body.dialog;
    assert(dialog.open);assert.match(dialog.innerHTML,/Ask About This/);
    if(method==='close')f.run('closeLearningLayer()');
    if(method==='escape')dialog.events.cancel({preventDefault(){}});
    if(method==='outside')dialog.events.click({target:dialog,clientX:100,clientY:100});
    assert.equal(f.body.dialog,null);assert.equal(f.app.innerHTML,'original card');assert.equal(f.content.scrollTop,180);assert.equal(f.context.window.scrollY,740);assert(f.focus.restored);
    assert.equal(f.run('panelIndex'),4);assert.equal(f.run('qFeedback.correct'),false);assert.equal(f.run('writingText'),'saved draft');assert.equal(f.run('reflectionState.responses.p'),'saved reflection');
  }
});
test('late support response cannot reopen dismissed sheet',async()=>{
  const f=fixture();const request=f.run('startSupport()');f.run('closeLearningLayer()');f.reply({path:{support_state:'resolved'}});await request;
  assert.equal(f.body.dialog,null);assert.equal(f.run('supportState'),null);assert.equal(f.app.innerHTML,'original card');
});
test('offline support and contextual questions work while events queue',()=>{
  const f=fixture();f.context.navigator.onLine=false;f.context.fetch=()=>{throw Error('Must not fetch')};
  f.run('startSupport()');assert.match(f.body.dialog.innerHTML,/What would help most/);
  f.run('askAboutThis({preventDefault(){}})');assert.match(f.answer.textContent,/audience/);
  f.run('closeLearningLayer();showWhyThisMatters()');f.run('askAboutThis({preventDefault(){}})');assert.match(f.answer.textContent,/how much detail a writer provides/);
  assert.equal(f.app.innerHTML,'original card');
});
test('questions are scoped to activity and support unit',()=>{
  const f=fixture();f.run("showWhyThisMatters();rememberLayerQuestion('my question');closeLearningLayer();showWhyThisMatters()");assert.match(f.body.dialog.innerHTML,/my question/);
  f.run("closeLearningLayer();currentActivity.activity_instance_id='b';showWhyThisMatters()");assert(!f.body.dialog.innerHTML.includes('my question'));
});

test('hub reveals four choices, keeps types separate, and bookmarks are accessible',()=>{
 const f=fixture();f.run('startSupport()');assert.match(f.body.dialog.innerHTML,/Explain It Another Way/);assert.match(f.body.dialog.innerHTML,/Show Me an Example/);assert.match(f.body.dialog.innerHTML,/Check My Understanding/);assert.match(f.body.dialog.innerHTML,/Find Another Resource/);
 for(const type of ['alternative_explanation','worked_example','comprehension_check','external_resource']){f.run(`chooseHelp('${type}')`);assert.equal(f.run('supportState.current_unit.support_unit_id'),type);assert.match(f.body.dialog.innerHTML,/Ask About This/);assert.equal(f.app.innerHTML,'original card')}
 assert.match(f.run("bookmarkControl(false,'toggleWeekSave()')"),/aria-label="Save".*aria-pressed="false"/);assert.match(f.run("bookmarkControl(true,'toggleWeekSave()')"),/aria-label="Saved".*aria-pressed="true"/);
});
