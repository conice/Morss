/* Selected A design reference. Fictional data, in memory only. */
'use strict';

async function startReference() {
const demo = await fetch('/assets/data/reader_demo.json').then(response => {
  if (!response.ok) throw new Error('Cannot load reading examples');
  return response.json();
});
const paths = {
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5"/>',
  inbox: '<path d="M4 4h16v16H4z" stroke-linejoin="round"/><path d="M4 13h5l1.5 3h3l1.5-3h5"/>',
  favorite: '<path class="favorite-icon" d="m12 3 2.8 5.7 6.3.9-4.6 4.4 1.1 6.3-5.6-3-5.6 3 1.1-6.3L3 9.6l6.2-.9L12 3Z" stroke-linejoin="round"/>',
  archive: '<rect x="4" y="7" width="16" height="14" rx="2"/><path d="M3 3h18v4H3zM9 12h6"/>',
  search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 4.5 4.5"/>',
  folder: '<path d="M3 7V5a2 2 0 0 1 2-2h5l2 3h7a2 2 0 0 1 2 2v11H3V7Z" stroke-linejoin="round"/>',
  chevron: '<path d="m9 5 7 7-7 7"/>',
  left: '<path d="m15 5-7 7 7 7"/>',
  refresh: '<path d="M20 7a8 8 0 0 0-14-2L3 8m0-5v5h5M4 17a8 8 0 0 0 14 2l3-3m0 5v-5h-5"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  book: '<path d="M12 5c-3-2-6-2-9-1v15c3-1 6-1 9 1 3-2 6-2 9-1V4c-3-1-6-1-9 1Zm0 0v15"/>',
  laptop: '<rect x="5" y="3" width="14" height="12" rx="2"/><path d="m5 15-3 5h20l-3-5M9 20h6"/>',
  phone: '<rect x="6" y="2" width="12" height="20" rx="3"/><path d="M10 5h4M11 19h2"/>',
  link: '<path d="m10 14 4-4m-5 7-1 1a4 4 0 0 1-6-6l4-4a4 4 0 0 1 6 0m0 8a4 4 0 0 0 6 0l4-4a4 4 0 0 0-6-6l-1 1"/>',
  settings: '<path d="m9 3-1 3-3 1-2 3 2 2-1 4 3 2h3l2 3 3-2 3-1 2-3-1-3 1-3-3-2-3-1-2-3Z" stroke-linejoin="round"/><circle cx="12" cy="12" r="3"/>',
  more: '<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
  external: '<path d="M14 3h7v7m0-7L10 14M10 4H4v16h16v-6"/>',
  check: '<path d="m5 12 4 4L19 6"/>',
  checkcircle: '<circle cx="12" cy="12" r="9"/><path d="m7 12 3 3 7-7"/>',
  translate: '<path d="M3 4h12M9 2v2M5 4c0 5 4 8 8 10M13 4c-1 6-5 10-10 12m11 5 4-11 4 11m-6-4h4"/>',
  sparkles: '<path d="m12 3 2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5L12 3Zm7-1v4m-2-2h4" stroke-linejoin="round"/>',
  chat: '<path d="M21 11a9 9 0 0 1-13 8l-5 2 1-6a9 9 0 1 1 17-4Z"/><path d="M8 10h8M8 14h5"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  close: '<path d="m6 6 12 12M6 18 18 6"/>',
  moon: '<path d="M20 14a9 9 0 0 1-10-11 9 9 0 1 0 10 11Z"/>',
  auto: '<path d="M13 2 4 14h7l-1 8 10-13h-7l1-7Z" stroke-linejoin="round"/>',
  trash: '<path d="M3 6h18M9 3h6m-10 3 1 15h12l1-15M10 10v7m4-7v7"/>',
  shield: '<path d="m12 2 8 3v7c0 5-8 10-8 10S4 17 4 12V5l8-3Z"/><path d="m8 11 3 3 5-5"/>',
  download: '<path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5"/>',
  text: '<path d="m3 20 6-16 6 16M5 15h8m4-3c6-3 5 4 5 8m-1-5c-6-1-6 6 1 3"/>',
  arrow: '<path d="M4 12h16m-6-6 6 6-6 6"/>',
  sliders: '<path d="M4 7h9m4 0h3M4 17h3m4 0h9"/><circle cx="15" cy="7" r="2"/><circle cx="9" cy="17" r="2"/>'
};
function icon(name, extra = '') {
  return `<svg class="${extra}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name] || paths.book}</svg>`;
}
function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, c => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' }[c]));
}
function iconButton(name, action, label, extra = '', data = '') {
  return `<button type="button" class="icon-button ${extra}" data-action="${action}" ${data} title="${esc(label)}" aria-label="${esc(label)}">${icon(name)}</button>`;
}
const sources = structuredClone(demo.sources);
const articles = structuredClone(demo.articles);
articles.forEach(a => { a.positions = {rss:0, full:a.progress}; a.userFavorite = null; a.results = {}; });
const backupArticles = structuredClone(articles);
const state = {
  view:'today', filter:'all', category:'all', source:'all', query:'', selected:'quiet', articleOpen:false,
  body:'full', mode:'original', fontSize:15, theme:'system', language:'zh', archiveId:null,
  sheet:null, online:true, sync:'已同步', lastSync:'刚刚', pending:0, lastAction:'打开 A 版阅读界面',
  devices:[{id:'windows',name:'书房的 Windows',online:true,trusted:true},{id:'android',name:'随身 Android',online:false,trusted:true}],
  rules:[{id:'flutter',name:'把技术好文留下',enabled:true,keyword:'Flutter',action:'提取全文 → 收藏'},{id:'design',name:'留一点设计灵感',enabled:false,keyword:'界面',action:'收藏'}],
  automationPaused:false, rulePreview:null, completedBatches:[],
  service:{url:'https://api.example.com/v1',model:'demo-reader',models:['demo-reader','demo-compact'],used:3,limit:50,directory:'示例目录 · 已保存',test:'尚未测试',configured:true},
  question:'', answer:'', restore:{archives:true,favorites:false,subscriptions:false,rules:false},
  versionToDelete:null, deviceToRevoke:null, lastBackupAction:'暂无', cacheCleared:false
};
const backupRules = structuredClone(state.rules);
let toastTimer, restoringScroll = false, returnFocus = null, lastReaderGesture = 0;
const app = document.getElementById('app');
const sourceFor = article => sources.find(s => s.id === article.source);
const currentArticle = () => articles.find(a => a.id === state.selected) || articles[0];
const versionFor = article => state.archiveId ? article.archives.find(v => v.id === state.archiveId) : null;
function contentFor(article) {
  const kind = versionFor(article)?.kind || state.body;
  return kind === 'rss' ? article.rss : article.paragraphs;
}
function sourceIcon(source) {
  return `<span class="source-icon" style="--source-bg:${source.bg};--source-color:${source.color}">${esc(source.short)}</span>`;
}
function searchableVersions(a) {
  const ordinary = a.cacheMissing ? '' : (a.extracted ? a.paragraphs : a.rss).join(' ');
  return [
    {text:ordinary,archive:null},
    ...a.archives.map(v => ({text:(v.kind === 'rss' ? a.rss : a.paragraphs).join(' '),archive:v.id})),
    ...Object.values(a.results).filter(r => r.task === 'translate').map(r => ({text:r.translated?.join(' ') || '',archive:r.archive,translated:true,body:r.kind}))
  ];
}
function brand() {
  return '<button class="brand" data-action="home" aria-label="Morss 首页"><img src="/assets/icons/morss.svg" alt=""><span class="brand-name">Morss</span></button>';
}
function countFor(view) {
  if (view === 'unread') return articles.filter(a => !a.read).length;
  if (view === 'favorites') return articles.filter(a => a.favorite).length;
  if (view === 'archive') return articles.filter(a => a.archives.length).length;
  return articles.length;
}
function titleForView() {
  if (state.source !== 'all') return sources.find(s => s.id === state.source)?.name || '订阅文章';
  if (state.category !== 'all') return state.category;
  return {today:'今日阅读',unread:'未读文章',favorites:'我的收藏',archive:'保留归档',search:'搜索文章'}[state.view];
}
function matchingArticles() {
  const words = state.query.toLocaleLowerCase().trim().split(/\s+/).filter(Boolean);
  return articles.filter(a => {
    if ((state.view === 'unread' || state.filter === 'unread') && a.read) return false;
    if ((state.view === 'favorites' || state.filter === 'favorites') && !a.favorite) return false;
    if (state.view === 'archive' && !a.archives.length) return false;
    if (state.category !== 'all' && sourceFor(a).category !== state.category) return false;
    if (state.source !== 'all' && a.source !== state.source) return false;
    return !words.length || searchableVersions(a).some(v => words.every(w => (a.title+' '+v.text).toLocaleLowerCase().includes(w)));
  }).sort((a,b) => {
    if (!words.length) return 0;
    return Number(words.every(w => b.title.toLocaleLowerCase().includes(w))) - Number(words.every(w => a.title.toLocaleLowerCase().includes(w)));
  });
}
function navItem(view, glyph, label) {
  const active = state.view === view && state.category === 'all' && state.source === 'all';
  return `<button class="nav-item ${active ? 'active' : ''}" data-action="navigate" data-view="${view}" ${active ? 'aria-current="page"' : ''}>${icon(glyph)}<span>${label}</span><span class="nav-count">${countFor(view)}</span></button>`;
}
function Sidebar() {
  return `<aside class="sidebar">${brand()}<p class="brand-sub">阅读，回到自己。</p><div class="sidebar-scroll"><nav class="nav-stack" aria-label="阅读导航">
    ${navItem('today','sun','今日阅读')}${navItem('unread','inbox','全部未读')}${navItem('favorites','favorite','我的收藏')}${navItem('archive','archive','保留归档')}
    </nav><div class="nav-label">我的分类</div><nav class="nav-stack" aria-label="文章分类">
    ${['技术','设计','生活'].map(c => `<button class="nav-item ${state.category === c ? 'active' : ''}" data-action="category" data-category="${c}">${icon('folder')}${c}<span class="nav-count">${articles.filter(a => sourceFor(a).category === c).length}</span></button>`).join('')}</nav>
    <div class="nav-label">订阅源<button data-action="subscribe" aria-label="添加订阅源">${icon('plus')}</button></div>
    <nav class="nav-stack" aria-label="订阅源">${sources.map(s => `<button class="nav-item ${state.source === s.id ? 'active' : ''}" data-action="source" data-source="${s.id}">${sourceIcon(s)}${esc(s.name)}<span class="nav-count">${articles.filter(a => a.source === s.id && !a.read).length || ''}</span></button>`).join('')}</nav></div>
    <div class="sidebar-bottom"><button class="nav-item" data-action="rules">${icon('auto')}自动化<span class="nav-count">${state.automationPaused ? '已暂停' : state.rules.filter(r => r.enabled).length}</span></button>
    <button class="sync-card" data-action="devices"><span class="sync-title">${icon('link')}${state.online ? '设备间，继续阅读' : '离线，也能安心阅读'}</span><span class="sync-caption">${state.online ? state.sync + ' · ' + state.lastSync : '本机内容仍然可用'}</span></button>
    <div class="profile"><span class="profile-avatar">M</span><small>我的阅读空间</small>${iconButton('settings','settings','打开设置')}</div></div></aside>`;
}
function MobileBrand() {
  return `<div class="mobile-brand">${brand()}<div>${iconButton('plus','subscribe','添加订阅') }${iconButton('settings','settings','设置')}</div></div>`;
}
function MobileNav() {
  return `<nav class="mobile-nav" aria-label="底部导航">${[['today','sun','阅读'],['favorites','favorite','收藏'],['archive','archive','归档'],['devices','laptop','设备']].map(([view,glyph,label]) => `<button class="${state.view === view ? 'active' : ''}" data-action="${view === 'devices' ? 'devices' : 'navigate'}" data-view="${view}">${icon(glyph)}${label}</button>`).join('')}</nav>`;
}
function SearchBox() {
  return `<label class="searchbox">${icon('search')}<input id="article-search" type="search" value="${esc(state.query)}" placeholder="搜索文章、正文与归档" aria-label="搜索本机文章与归档" autocomplete="off"><span class="shortcut">⌘ K</span></label>`;
}
function FilterTabs() {
  return `<div class="filter-tabs" aria-label="文章筛选">${[['all','全部'],['unread','未读'],['favorites','收藏']].map(([key,label]) => `<button data-action="filter" data-filter="${key}" class="${state.filter === key ? 'selected' : ''}" aria-pressed="${state.filter === key}">${label}${key === 'all' ? '<span>'+matchingArticles().length+'</span>' : ''}</button>`).join('')}</div>`;
}
function ResumeCard() {
  const a = articles.find(item => item.progress > 0 && item.progress < 100) || currentArticle();
  return `<button class="resume-card" data-action="resume" data-id="${a.id}"><span class="resume-icon">${icon('book')}</span><span class="resume-copy"><small>接着上次 · 已读 ${a.progress}%</small><p>${esc(a.title)}</p></span>${icon('chevron')}</button>`;
}
function articleBadge(a) {
  if (a.archives.length) return `${icon('archive')} ${a.archives.length > 1 ? a.archives.length+' 份归档' : '已离线保存'}`;
  return a.favorite ? '暂无离线归档' : '';
}
function ArticleItem(a, selected = true) {
  const s = sourceFor(a);
  let excerpt = a.deck;
  if (state.query.trim()) {
    const words = state.query.toLocaleLowerCase().trim().split(/\s+/);
    const hit = searchableVersions(a).find(v => words.every(w => (a.title+' '+v.text).toLocaleLowerCase().includes(w)));
    if (hit?.text) {
      const at = Math.max(0,hit.text.toLocaleLowerCase().indexOf(words[0])-15);
      excerpt = (at ? '…' : '')+hit.text.slice(at,at+68)+'…';
    }
  }
  return `<button class="article-item ${selected && state.selected === a.id ? 'selected' : ''}" data-action="article" data-id="${a.id}">
    <div class="item-source">${sourceIcon(s)}${esc(s.name)}<span class="item-time">${a.time}</span></div>
    <div class="item-layout"><div><h3>${esc(a.title)}</h3><p>${esc(excerpt)}</p></div><img src="/assets/images/${a.image}.jpg" alt="" loading="lazy"></div>
    <div class="item-footer"><span class="unread-dot ${a.read ? 'read-dot' : ''}"></span>${a.minutes} 分钟阅读<span class="item-saved">${articleBadge(a)}</span></div></button>`;
}
function EmptyState() {
  return `<div class="empty-state">${icon(state.view === 'archive' ? 'archive' : 'book')}<h3>${state.query ? '还没有找到这篇文章' : '这里，留给下一篇好文章'}</h3><p>${state.view === 'favorites' ? '点击文章上的星标，把喜欢的内容留下。' : state.view === 'archive' ? '归档会保留正文，取消收藏也能在这里找到。' : '换个关键词，或查看全部文章。'}</p><button class="secondary-button" data-action="home">查看全部文章</button></div>`;
}
function Inbox() {
  const list = matchingArticles();
  return `<section class="inbox" aria-label="文章列表"><header class="inbox-heading">${MobileBrand()}<p class="eyebrow">9 月 12 日 · 星期六</p><div class="heading-row"><h1>${esc(titleForView())}</h1>${iconButton('refresh','refresh','刷新订阅')}</div>${SearchBox()}${FilterTabs()}</header>
    <div class="inbox-scroll">${state.view === 'today' && !state.query && state.source === 'all' ? ResumeCard() : ''}<div class="list-label"><span>${state.query ? '本机搜索结果' : state.view === 'archive' ? '保留的内容 · 不随取消收藏删除' : '为你留着的好内容'}</span><button data-action="mark-all">全部已读</button></div>${list.length ? list.map(a => ArticleItem(a)).join('') : EmptyState()}</div></section>`;
}
function Reader() {
  const a = currentArticle(), s = sourceFor(a), version = versionFor(a);
  const content = contentFor(a), kind = version?.kind || state.body;
  const positionKey = version?.id || kind;
  const translated = state.mode === 'bilingual' && a.english.length;
  const missing = a.cacheMissing && !version;
  return `<section class="reader" aria-label="文章正文"><div class="reader-topbar"><div class="breadcrumb">${iconButton('left','back','返回文章列表','mobile-back reader-back')}<span>${s.category}</span>${icon('chevron')}<span>${esc(s.name)}</span></div><div class="toolbar-actions">
    ${iconButton('favorite','favorite',a.favorite ? '取消收藏，保留归档' : '收藏文章',a.favorite ? 'is-on' : '')}
    ${iconButton('archive','versions','查看归档版本')}
    ${iconButton('more','article-menu','更多阅读操作')}</div></div>
    <div class="reader-scroll" id="reader-scroll" tabindex="0"><article><div class="article-kicker"><span></span>${s.category.toUpperCase()}与灵感 · ${version ? '历史归档' : '慢一点，也很好'}</div>
    <h2 class="article-title">${esc(a.title)}</h2><p class="article-deck">${esc(a.deck)}</p>
    <div class="article-byline">${sourceIcon(s)}<span>${esc(s.name)}</span><span class="byline-divider">·</span><span>${a.time === '昨天' ? '9 月 11 日' : '9 月 12 日'}</span><span class="byline-divider">·</span><span>${a.minutes} 分钟</span><span class="saved-label">${icon(missing ? 'clock' : 'checkcircle')}${missing ? '正文已清理' : version ? version.date : '本机可离线阅读'}</span></div>
    <figure class="hero-figure"><img src="/assets/images/${a.image}.jpg" alt="${{mountain:'阳光下连绵的山峰',forest:'光线穿过绿色森林',architecture:'明亮建筑的几何线条',desk:'桌上的书本与笔记',coast:'海岸的浪花'}[a.image]}"><figcaption>${a.id === 'quiet' ? '留一点空白，让好内容慢慢发生。' : '每一篇值得停留的文字，都有自己的风景。'}</figcaption></figure>
    <div class="reading-tools"><div class="source-tabs" aria-label="正文来源"><button data-action="body" data-body="rss" class="${kind === 'rss' ? 'selected' : ''}">RSS 正文</button><button data-action="${a.extracted ? 'body' : 'extract'}" data-body="full" class="${kind === 'full' ? 'selected' : ''}">${a.extracted ? '提取全文' : '提取全文 + '}</button></div>
    <div class="ai-actions"><button data-action="translation" class="${translated ? 'selected' : ''}">${icon('translate')}译文对照</button><button data-action="summary">${icon('sparkles')}摘要</button><button data-action="ask">${icon('chat')}问问文章</button></div></div>
    ${version ? `<p class="form-message">正在查看 ${version.date} 保存的${kind === 'rss' ? ' RSS 正文' : '全文'}；源站更新不会替换这份快照。</p>` : ''}
    ${kind === 'rss' ? '<p class="form-message">此订阅仅提供摘要。可以提取公开网页全文，或查看原网页入口。</p>' : ''}
    <div class="article-body" style="--reading-size:${state.fontSize}px">${missing ? '<div class="empty-state"><h3>本机正文缓存已清理</h3><p>保留的标题仍然可搜，归档版本也仍可阅读。</p><button class="secondary-button" data-action="refill">从配对设备补取正文</button></div>' : content.map((p,i) => `${i === 2 ? '<h3>给日常，留一点空白</h3>' : ''}<p id="paragraph-${i}">${esc(p)}</p>${translated && a.english[i] ? `<div class="translated"><small>English · 段落 ${i+1}</small>${esc(a.english[i])}</div>` : ''}${a.id === 'quiet' && i === 2 ? '<blockquote>不必读完所有的文章，只要记得为什么开始。</blockquote>' : ''}`).join('')}
    ${!missing ? '<div class="body-ending">· · ·</div>' : ''}</div></article></div>
    <footer class="reader-footer"><div><span id="reading-percent">${a.positions[positionKey] || 0}%</span><span class="progress-track"><i id="reading-progress" style="width:${a.positions[positionKey] || 0}%"></i></span></div><div><button data-action="appearance" aria-label="阅读字号和外观">${icon('text')}</button><button data-action="read">${icon(a.read ? 'checkcircle' : 'check')}${a.read ? '已读' : '标为已读'}</button><button data-action="original">原网页${icon('external')}</button></div></footer></section>`;
}
function ReadingDesk() {
  return `<div class="app-shell reading-desk ${state.articleOpen ? 'article-open' : ''}">${Sidebar()}${Inbox()}${Reader()}${MobileNav()}</div>`;
}
function snapshot() {
  return {
    方向:'A · 玻璃阅读台', 布局:'订阅栏 / 文章列表 / 正文', 最近操作:state.lastAction,
    页面:state.view, 筛选:{filter:state.filter,category:state.category,source:state.source,query:state.query}, 当前文章:state.selected,
    正文:{source:state.body,archive:state.archiveId,mode:state.mode,fontSize:state.fontSize}, 外观:state.theme,
    网络演示:{online:state.online,sync:state.sync,pending:state.pending,lastSync:state.lastSync,devices:state.devices},
    文章状态:articles.map(a => ({id:a.id,read:a.read,favorite:a.favorite,archives:a.archives,positions:a.positions,cacheMissing:!!a.cacheMissing,results:Object.keys(a.results)})),
    自动化:{rules:state.rules,paused:state.automationPaused,completedBatches:state.completedBatches},
    服务演示:state.service, 恢复选择:state.restore, 最近备份操作:state.lastBackupAction,
    边界:'全部为内存中的示例数据；没有真实抓取、同步、AI 请求、持久化或密钥存储。'
  };
}
function updateInspector() {
  window.morssReferenceState = structuredClone(snapshot());
}
function applyTheme() {
  document.documentElement.dataset.theme = state.theme === 'system' ? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light') : state.theme;
}
function render(preserve = true) {
  const oldScroll = document.getElementById('reader-scroll')?.scrollTop || 0;
  const listScroll = document.querySelector('.inbox-scroll')?.scrollTop || 0;
  const focus = document.activeElement, focusId = focus?.id, selection = focus?.selectionStart;
  const selectionEnd = focus?.selectionEnd;
  applyTheme();
  app.innerHTML = ReadingDesk();
  const reader = document.getElementById('reader-scroll');
  if (reader) {
    restoringScroll = true;
    if (preserve) reader.scrollTop = oldScroll;
    reader.addEventListener('scroll', handleReaderScroll, {passive:true});
    for (const name of ['wheel','touchmove','keydown']) reader.addEventListener(name,() => { lastReaderGesture = Date.now(); },{passive:true});
    requestAnimationFrame(() => { restoringScroll = false; });
  }
  if (preserve && document.querySelector('.inbox-scroll')) document.querySelector('.inbox-scroll').scrollTop = listScroll;
  const input = focusId && document.getElementById(focusId);
  if (input && focus?.tagName === 'INPUT' && ['search','text'].includes(input.type)) {
    input.focus({preventScroll:true});
    if (selection !== null) input.setSelectionRange(selection,selectionEnd);
  }
  updateInspector();
}
function handleReaderScroll(event) {
  if (restoringScroll || state.sheet) return;
  const el = event.currentTarget;
  if (el.scrollHeight - el.clientHeight < 40) return;
  const a = currentArticle(), kind = versionFor(a)?.kind || state.body;
  const progress = Math.min(100,Math.round(el.scrollTop / (el.scrollHeight-el.clientHeight) * 100));
  a.positions[state.archiveId || kind] = progress; a.progress = progress; a.lastRead = {kind,archive:state.archiveId};
  const percent = document.getElementById('reading-percent'), bar = document.getElementById('reading-progress');
  if (percent) percent.textContent = progress+'%';
  if (bar) bar.style.width = progress+'%';
  if (progress >= 99 && !a.read && (!a.cacheMissing || versionFor(a)) && Date.now()-lastReaderGesture < 1800) {
    a.read = true; state.lastAction = '读到当前正文末尾，标为已读'; state.pending += 1;
    render(); notify('已经读完，替你记下了。');
  } else updateInspector();
}
function notify(message) {
  const toast = document.getElementById('toast');
  clearTimeout(toastTimer);
  toast.textContent = message;
  toast.classList.add('visible');
  toastTimer = setTimeout(() => toast.classList.remove('visible'), 3000);
}
function openArticle(id, resume = false) {
  state.selected = id; state.articleOpen = true; state.mode = 'original'; state.archiveId = null;
  const a = currentArticle();
  if (state.view === 'archive' && a.archives.length) state.archiveId = a.archives[0].id;
  const words = state.query.toLocaleLowerCase().trim().split(/\s+/).filter(Boolean);
  const hit = words.length && searchableVersions(a).find(v => words.every(w => (a.title+' '+v.text).toLocaleLowerCase().includes(w)));
  if (hit?.archive) state.archiveId = hit.archive;
  state.body = versionFor(a)?.kind || (hit?.body || (a.extracted ? 'full' : 'rss'));
  if (hit?.translated) state.mode = 'bilingual';
  if (resume && a.lastRead) {
    state.archiveId = a.archives.some(v => v.id === a.lastRead.archive) ? a.lastRead.archive : null;
    state.body = a.lastRead.kind;
  }
  state.lastAction = (resume ? '继续阅读 ' : '打开文章 ')+a.title;
  render(false);
  if (hit && !resume) {
    const index = contentFor(a).findIndex((p,i) => words.some(w => (hit.translated ? a.english[i] || '' : p).toLocaleLowerCase().includes(w)));
    if (index >= 0) {
      lastReaderGesture = 0;
      document.getElementById('paragraph-'+index)?.scrollIntoView({block:'center'});
    }
  }
  if (resume) {
    const el = document.getElementById('reader-scroll');
    restoringScroll = true;
    requestAnimationFrame(() => {
      el.scrollTop = (el.scrollHeight-el.clientHeight) * a.progress / 100;
      requestAnimationFrame(() => { restoringScroll = false; });
    });
  }
}
function navigate(view) {
  state.view = view; state.filter = 'all'; state.category = 'all'; state.source = 'all'; state.query = ''; state.articleOpen = false;
  state.lastAction = '打开'+titleForView(); render(false);
}

function settingLink(glyph, title, caption, action) {
  return `<div class="setting-row">${icon(glyph)}<div><strong>${title}</strong><p>${caption}</p></div><button data-action="${action}" aria-label="${title}">${icon('chevron')}</button></div>`;
}
function toggle(action, on, label, extra = '') {
  return `<button class="switch ${on ? 'on' : ''}" role="switch" aria-checked="${on}" aria-label="${label}" data-action="${action}" ${extra}></button>`;
}
function sheetData(kind) {
  const a = currentArticle(), s = sourceFor(a), body = versionFor(a)?.kind || state.body;
  const articleIntro = esc(a.title)+' · '+(body === 'rss' ? 'RSS 摘要' : '当前全文');
  if (kind === 'settings') return {
    title:'你的阅读，随你喜欢', intro:'把工具调成舒服的样子，然后回到内容。',
    html:`<div class="setting-card">${settingLink('text','阅读与外观','字号、明暗与跟随系统','appearance')}${settingLink('sparkles','翻译与 AI','服务地址、模型与每日调用额度','service')}${settingLink('auto','自动化','让重复的小事自动发生','rules')}${settingLink('laptop','我的设备','局域网配对与同步','devices')}${settingLink('archive','备份与恢复','每日备份，保留最近 7 份','backup')}${settingLink('download','存储空间','普通缓存与长期归档分别管理','storage')}</div>`
  };
  if (kind === 'appearance') return {
    title:'读得舒服一点', intro:'外观随系统切换，字号只影响你的阅读体验。',
    html:`<section class="sheet-section"><h3>外观</h3><div class="theme-options">${[['light','sun','浅色'],['dark','moon','深色'],['system','laptop','跟随系统']].map(([key,glyph,label]) => `<button class="theme-option ${state.theme === key ? 'selected' : ''}" data-action="theme" data-theme="${key}" aria-pressed="${state.theme === key}">${icon(glyph)}${label}</button>`).join('')}</div></section><section class="sheet-section"><h3>正文字号 <output id="font-size-value">${state.fontSize}px</output></h3><div class="range-row"><span>A</span><input id="font-size" type="range" min="13" max="22" value="${state.fontSize}" aria-label="正文字号"><span style="font-size:25px">A</span></div><p class="form-message" id="font-preview" style="font-size:${state.fontSize}px">不急着读完世界，先找回自己的节奏。</p></section>`
  };
  if (kind === 'devices') return {
    title:'在另一台设备，接着读', intro:'设备处于同一局域网、两端应用同时打开时，就能交换阅读状态和归档。',
    html:`<div class="device-art">${icon('phone')}<span class="connection">···</span>${icon('link')}<span class="connection">···</span>${icon('laptop')}</div><div class="setting-card"><div class="setting-row">${icon('phone')}<div><strong>这台设备</strong><p>本机数据已保存 · ${state.online ? '当前可连接局域网' : '离线阅读中'}</p></div></div>${state.devices.map(d => `<div class="setting-row">${icon(d.id.includes('windows') ? 'laptop' : 'phone')}<div><strong>${esc(d.name)}</strong><p><span class="status-dot ${!d.online || !d.trusted || !state.online ? 'off' : ''}"></span>${!d.trusted ? '授权已撤销 · 已保存数据保留' : d.online && state.online ? '同网且已打开 · 可以同步' : '等待同网并打开应用'}${d.revocationPending ? ' · 待接收撤销信息' : ''}</p></div>${d.trusted ? `<button data-action="revoke" data-id="${d.id}">撤销</button>` : '<span class="subtle">已断开</span>'}</div>`).join('')}</div><div class="button-row"><button class="primary-button" data-action="sync">${icon('refresh')}立即同步</button><button class="secondary-button" data-action="pair">${icon('plus')}配对新设备</button></div><p class="form-message">${state.sync} · 最后成功：${state.lastSync} · 待同步 ${state.pending} 项</p><div class="setting-row"><div><strong>局域网连接 · 演示开关</strong><p>关闭后仍可阅读、收藏及管理本机内容。</p></div>${toggle('network',state.online,'模拟局域网连接')}</div>`
  };
  if (kind === 'pair') return {
    title:'让设备认出彼此', intro:'在另一台设备选择“输入配对码”，确认后开始连接。此处使用固定演示码。',
    html:`<div class="pair-code">426 810</div><label class="field"><span>输入另一台设备的配对码</span><input id="pair-code" inputmode="numeric" maxlength="7" placeholder="426 810" autocomplete="off"></label><button class="primary-button full-width" data-action="confirm-pair">确认配对 · 演示</button><p class="form-message">新安装拥有独立设备身份。恢复备份后也需要重新配对。</p>`
  };
  if (kind === 'revoke') {
    const device = state.devices.find(d => d.id === state.deviceToRevoke);
    return {title:'撤销这台设备的授权？',intro:esc(device?.name || ''),html:`<p class="form-message">本机立即停止与它的新同步及未完成传输。其他可信设备收到撤销信息后生效；离线设备要等下次收到信息。已经保存的数据会保留，重新加入需要再次配对。</p><div class="button-row"><button class="secondary-button" data-action="devices">保留授权</button><button class="danger-button" data-action="confirm-revoke">撤销授权</button></div>`};
  }
  if (kind === 'versions') return {
    title:'值得留下的版本', intro:esc(a.title)+'。收藏标记与实际保存的归档分别管理。',
    html:`<div class="setting-card">${a.archives.length ? a.archives.map(v => `<div class="archive-version">${icon('archive')}<button data-action="open-version" data-id="${v.id}"><strong>${v.kind === 'full' ? '提取全文' : 'RSS 正文'} · ${v.date}</strong><small>正文与图片已保存${v.results.length ? ' · 附带'+v.results.join('、') : ''}</small></button>${iconButton('trash','delete-version','删除这份归档','','data-id="'+v.id+'"')}</div>`).join('') : '<div class="empty-state"><h3>当前没有离线归档</h3><p>收藏和已读标记仍然保留。<br>可以手动保存正在阅读的正文。</p></div>'}</div><div class="button-row"><button class="primary-button" data-action="save-archive">${icon('plus')}${a.archives.length ? '重新归档当前正文' : '保存当前正文'}</button><button class="secondary-button" data-action="favorite">${icon('favorite')}${a.favorite ? '取消收藏' : '添加收藏'}</button></div><p class="form-message">取消收藏后，这些版本仍可从“保留归档”访问、搜索、同步和恢复。</p>`
  };
  if (kind === 'delete-version') {
    const v = a.archives.find(item => item.id === state.versionToDelete);
    return {title:'删除这份归档？',intro:esc(a.title),html:`<div class="form-message">将删除 ${v?.date} 的${v?.kind === 'rss' ? ' RSS 正文' : '全文'}快照及图片。${v?.results.length ? '附加结果也会删除：'+v.results.join('、')+'。' : '此版本没有附加生成结果。'}<br>删除会参与局域网同步，其他归档和收藏、已读标记保留。</div><div class="button-row"><button class="secondary-button" data-action="versions">保留这份归档</button><button class="danger-button" data-action="confirm-delete-version">删除这份归档</button></div>`};
  }
  if (kind === 'translation') return {
    title:'换一种语言，继续阅读', intro:articleIntro,
    html:`<label class="field"><span>目标语言</span><select id="translation-language"><option value="zh" ${state.language === 'zh' ? 'selected' : ''}>简体中文</option><option value="en" ${state.language === 'en' ? 'selected' : ''}>English</option></select></label><p class="form-message">${state.language === 'zh' ? '这篇示例的原文已是简体中文。选择 English 可以体验逐段对照。' : '译文与原文逐段对应，共用这个正文版本的阅读位置。'}<br>生成或切换译文不会自动把文章标为已读。</p><div class="button-row"><button class="primary-button" data-action="translate">${icon('translate')}打开逐段对照</button>${state.mode === 'bilingual' ? '<button class="secondary-button" data-action="original-mode">仅看原文</button>' : ''}</div><p class="subtle" style="margin-top:15px">对照页使用预先写好的示例译文，不调用在线服务。</p>`
  };
  if (kind === 'summary') {
    const points = body === 'rss' ? [a.paragraphs[0]] : a.summary;
    const refs = body === 'rss' ? [0] : a.id === 'quiet' ? [1,2,4] : [0,1,2];
    return {title:'先读一个小摘要',intro:articleIntro,html:`<p class="subtle">${body === 'rss' ? '依据订阅提供的摘要，不代表完整文章。' : '依据当前正文；点击段落标记可以回到原文。'}</p><ol class="summary-points">${points.map((point,i) => `<li><span>0${i+1}</span><div>${esc(point)}<br><button class="citation" data-action="citation" data-paragraph="${refs[i]}">原文 ${refs[i]+1} 段 ↗</button></div></li>`).join('')}</ol><div class="button-row"><button class="secondary-button" data-action="save-archive">${icon('archive')}连同原文保存</button><button class="primary-button" data-action="close-sheet">回到阅读</button></div><p class="subtle" style="margin-top:15px">示例结果 · 关联当前原文版本 · 阅读摘要不改变已读状态</p>`};
  }
  if (kind === 'ask') return {
    title:'问问这篇文章', intro:articleIntro,
    html:`<label class="field"><span>你想了解什么？</span><textarea id="article-question" rows="3" placeholder="这篇文章最重要的建议是什么？">${esc(state.question)}</textarea></label><button class="primary-button full-width" data-action="send-question">${icon('chat')}提问 · 演示</button>${state.answer ? `<div class="answer">${esc(state.answer)}<br><button class="citation" data-action="citation" data-paragraph="0">查看当前原文 ↗</button></div>` : '<p class="form-message">只讨论当前文章。正文没有足够信息时，会明确说明。</p>'}<p class="subtle" style="margin-top:15px">此对照页展示预设回答和引用交互，没有向模型发送文章。</p>`
  };
  if (kind === 'service') return {
    title:'把喜欢的模型接进来', intro:'填写你自己的服务地址与模型。此页面只演示配置状态，不发送网络请求。',
    html:`<label class="field"><span>服务 URL · 完整接口前缀</span><input id="service-url" type="url" value="${esc(state.service.url)}" placeholder="https://api.example.com/v1" autocomplete="off"><small>保留服务商的完整路径前缀，不重复添加 /v1。</small></label><label class="field"><span>API Key</span><input id="service-key" type="password" autocomplete="off" placeholder="仅填示例文本，无需真实密钥"><small>对照页不保存输入的密钥。正式版由各设备在系统安全存储中单独配置。</small></label>
    <button class="secondary-button full-width" data-action="save-service">保存配置并获取示例模型列表</button><section class="sheet-section"><label class="field"><span>选择模型 · ${esc(state.service.directory)}</span><select id="service-model"><option value="">请选择模型</option>${state.service.models.map(model => `<option value="${esc(model)}" ${state.service.model === model ? 'selected' : ''}>${esc(model)}</option>`).join('')}</select></label><label class="field"><span>也可以手动填写模型 ID</span><input id="manual-model" placeholder="目录不可用时填写模型 ID" autocomplete="off"></label><label class="field"><span>每设备每日调用上限</span><input id="call-limit" type="number" min="1" max="1000" value="${state.service.limit}"></label><p class="form-message">今日演示调用 ${state.service.used} / ${state.service.limit} 次。目录读取不占额度；文章生成与模型测试共用额度。</p><div class="button-row"><button class="secondary-button" data-action="refresh-models">刷新目录</button><button class="primary-button" data-action="model-test">测试当前模型</button></div><p class="subtle" style="margin-top:12px">${esc(state.service.test)}</p></section>`
  };
  if (kind === 'model-test') return {
    title:'测试当前模型', intro:esc(state.service.model || '尚未选择模型'),
    html:`<p class="form-message">正式服务会收到一段固定短文本，可能产生费用，计入本设备每日额度。成功仅代表这一次文本调用可用。<br>此对照页只演示调用计数与结果，不发出请求。</p><div class="button-row"><button class="secondary-button" data-action="service">返回配置</button><button class="primary-button" data-action="confirm-model-test">发送演示测试</button></div>`
  };
  if (kind === 'rules') return {
    title:'让小事，自动发生', intro:'先预览，再放心交给规则。默认只执行第一条命中的规则，新建或修改后只影响之后的新文章。',
    html:`${state.automationPaused ? '<p class="form-message">恢复后，本机自动化已暂停。预览规则后再启用。</p>' : ''}<div class="setting-card">${state.rules.map((rule,i) => `<div class="setting-row"><span class="subtle">0${i+1}</span><div><strong>${rule.name}</strong><div class="rule-chain"><span>新文章</span>${icon('chevron')}<span>标题含 ${rule.keyword}</span>${icon('chevron')}<span>${rule.action}</span></div></div>${toggle('toggle-rule',rule.enabled,'启用'+rule.name,`data-id="${rule.id}"`)}</div>`).join('')}</div><div class="button-row"><button class="secondary-button" data-action="preview-rules">预览已有文章</button>${state.automationPaused ? '<button class="primary-button" data-action="enable-automation">启用本机自动化</button>' : ''}</div>
    ${state.rulePreview ? `<section class="sheet-section"><h3>本次预览 · ${state.rulePreview.length} 篇命中</h3><div class="setting-card">${state.rulePreview.map(id => {const item = articles.find(article => article.id === id); return `<div class="setting-row">${icon('book')}<div><strong>${esc(item.title)}</strong><p>${item.userFavorite !== null ? '已有手动收藏决定，此字段将受到保护' : item.favorite ? '已经收藏，不追加自动归档' : '将提取正文并首次收藏'}</p></div></div>`;}).join('') || '<p class="form-message">当前启用规则没有命中示例文章。</p>'}</div><button class="primary-button full-width" style="margin-top:15px" data-action="run-rules">手动执行这批文章</button></section>` : ''}<p class="form-message">手动收藏与取消收藏优先于规则。重复执行同一批示例不会再创建相同归档。</p>`
  };
  if (kind === 'backup') return {
    title:'把阅读，好好留下', intro:'每天首次启动备份，保留最近 7 份。归档即使已取消收藏，也在备份范围内。',
    html:`<div class="setting-card"><div class="setting-row">${icon('shield')}<div><strong>今天 09:12 · 本地备份</strong><p>订阅、阅读状态、保留归档及规则 · 示例</p></div><span class="subtle">最近一份</span></div></div><section class="sheet-section"><h3>选择恢复到已有数据的设备</h3><div class="setting-card">${[['archives','保留归档','包括取消收藏后的正文、图片和附加结果'],['favorites','收藏标记','单独恢复归档不会自动变成收藏'],['subscriptions','订阅与分类','按新的修改参与合并'],['rules','自动化规则','恢复后，本机先暂停自动执行']].map(([key,title,caption]) => `<label class="selection-row"><input type="checkbox" data-restore="${key}" ${state.restore[key] ? 'checked' : ''}><span>${title}<small>${caption}</small></span></label>`).join('')}</div><div class="button-row"><button class="secondary-button" data-action="export-backup">加密导出预览</button><button class="primary-button" data-action="restore-backup">恢复所选 · 演示</button></div><p class="form-message">新安装用独立身份重新配对。已有安装沿用当前身份与授权，备份不含配对凭据和 API Key。<br>此处从初始示例数据恢复，不读写备份文件。</p></section>`
  };
  if (kind === 'export-backup') return {
    title:'为导出的备份设个密码', intro:'这是加密导出流程的界面预览，对照页不会创建实际备份文件。',
    html:`<label class="field"><span>备份密码</span><input id="backup-password" type="password" placeholder="填写演示密码" autocomplete="off"></label><p class="form-message">包含保留归档及业务数据，排除普通缓存、API Key 和配对凭据。</p><button class="primary-button full-width" data-action="confirm-export">预览导出结果</button>`
  };
  if (kind === 'storage') return {
    title:'留住喜欢的，清理临时的', intro:'普通缓存默认保留 30 天。归档长期保留，删除需要单独操作。',
    html:`<div class="setting-card"><div class="setting-row">${icon('clock')}<div><strong>普通正文和生成结果</strong><p>${state.cacheCleared ? '本机缓存已清理 · 演示状态' : '近期阅读内容；清理只影响本机'}</p></div><button data-action="confirm-cleanup">清理</button></div><div class="setting-row">${icon('archive')}<div><strong>保留归档 · ${articles.reduce((n,item) => n+item.archives.length,0)} 份</strong><p>包含已取消收藏的内容，不随缓存清理</p></div><button data-action="archive-view">查看</button></div></div><p class="form-message">普通生成结果仍被保留时，其准确原文也一并保留。主动清理原文，会列出并清理失去依据的本机普通结果。</p>`
  };
  if (kind === 'confirm-cleanup') return {
    title:'清理本机普通缓存？', intro:'将清理示例文章的普通正文及其关联普通生成结果，也会移除对应正文搜索命中。',
    html:'<p class="form-message">所有保留归档及其中的附加结果仍在；已读、收藏标记和其他设备副本不受影响。</p><div class="button-row"><button class="secondary-button" data-action="storage">暂时保留</button><button class="danger-button" data-action="cleanup">清理这些缓存</button></div>'
  };
  if (kind === 'subscribe') return {
    title:'把喜欢的声音，加进来', intro:'支持 RSS、Atom 和 OPML。同一订阅源重复添加会合并。',
    html:`<label class="field"><span>订阅源名称</span><input id="feed-name" placeholder="例如：慢读 Slow Reading"></label><label class="field"><span>RSS / Atom 地址</span><input id="feed-url" type="url" placeholder="https://example.com/feed.xml"></label><label class="field"><span>分类</span><select id="feed-category"><option>生活</option><option>设计</option><option>技术</option></select></label><button class="primary-button full-width" data-action="add-feed">添加示例订阅</button><p class="form-message">本对照页只添加内存中的订阅入口，不抓取网页。OPML 的解析、导入和导出留待正式实现。</p>`
  };
  if (kind === 'article-menu') return {
    title:'这篇文章', intro:esc(a.title),
    html:`<div class="setting-card">${settingLink('check',a.read ? '标为未读' : '标为已读','手动调整阅读状态','read')}${settingLink('archive','归档版本',a.archives.length+' 份保留快照','versions')}${settingLink('text','阅读外观','字号与明暗','appearance')}${settingLink('external','原网页入口','离开应用继续阅读的入口预览','original')}</div>`
  };
  if (kind === 'original') return {
    title:'原网页入口', intro:esc(a.title),
    html:`<p class="form-message">这里的文章由对照页自带的示例文字组成，没有对应的公开原网页。正式阅读流程会保留订阅条目的原始链接，在提取失败或缓存清理后仍可访问。</p><button class="primary-button full-width" data-action="close-sheet">继续阅读示例</button>`
  };
  return {title:'Morss',intro:'',html:''};
}
function showSheet(kind) {
  if (!state.sheet) returnFocus = document.activeElement;
  state.sheet = kind; renderSheet();
}
function renderSheet() {
  if (!state.sheet) return;
  const data = sheetData(state.sheet);
  document.getElementById('modal-root').innerHTML = `<div class="overlay" data-action="dismiss-overlay"><section class="sheet ${data.wide ? 'wide' : ''}" role="dialog" aria-modal="true" aria-labelledby="sheet-title" tabindex="-1"><div class="sheet-heading"><h2 id="sheet-title">${data.title}</h2>${iconButton('close','close-sheet','关闭')}</div><p class="sheet-intro">${data.intro}</p>${data.html}</section></div>`;
  app.inert = true;
  document.querySelector('.sheet').focus({preventScroll:true});
}
function closeSheet() {
  state.sheet = null; document.getElementById('modal-root').innerHTML = '';
  app.inert = false;
  if (returnFocus?.isConnected) returnFocus.focus({preventScroll:true});
}
function saveArchive(a, fromRule = false) {
  const kind = versionFor(a)?.kind || state.body;
  a.archives.unshift({
    id:a.id+'-'+Date.now()+'-'+a.archives.length, kind:fromRule ? 'full' : kind, date:'今天 · 刚刚',
    results:[...new Set(Object.values(a.results).filter(r => r.body === (fromRule ? 'full' : state.archiveId || kind)).map(r => r.task === 'summary' ? '文章摘要' : r.task === 'translate' ? '译文' : '文章问答'))]
  });
  state.pending += 1;
}
function useGeneration(task) {
  const a = currentArticle(), key = [task,state.archiveId || state.body,state.service.url,state.service.model,state.language,task === 'question' ? state.question : ''].join('|');
  if (a.results[key] && task !== 'question' && task !== 'test') return true;
  if (a.cacheMissing && !versionFor(a)) { notify('先补取原文，或打开一份保留归档。'); return false; }
  if (!state.service.model) { showSheet('service'); notify('先选择模型，再开始生成。'); return false; }
  if (state.service.used >= state.service.limit) { notify('已达到今天的演示调用额度，已有结果仍可阅读。'); return false; }
  state.service.used += 1;
  a.results[key] = {task,body:state.archiveId || state.body,kind:versionFor(a)?.kind || state.body,archive:state.archiveId,model:state.service.model,service:state.service.url,language:state.language,original:[...contentFor(a)],translated:task === 'translate' ? a.english.slice(0,contentFor(a).length) : []};
  state.lastAction = '展示预设'+task+'结果（没有网络请求）';
  updateInspector();
  return true;
}
function runSync() {
  if (!state.online || !state.devices.some(d => d.online && d.trusted)) { notify('等待同一局域网内的配对设备打开应用。'); return; }
  if (state.sync === '正在同步') return;
  state.sync = '正在同步'; state.lastAction = '模拟同步阅读状态，然后同步归档';
  render(); if (state.sheet === 'devices') renderSheet();
  setTimeout(() => {
    if (!state.online || !state.devices.some(d => d.online && d.trusted)) { state.sync = '等待连接'; render(); if (state.sheet === 'devices') renderSheet(); return; }
    state.sync = '已同步'; state.pending = 0; state.lastSync = '刚刚';
    state.devices.forEach(d => { if (d.trusted && d.online) d.revocationPending = false; });
    render(); if (state.sheet === 'devices') renderSheet(); notify('演示同步完成，阅读进度与归档已对齐。');
  },900);
}

document.addEventListener('click', event => {
  const button = event.target.closest('[data-action]');
  if (!button || button.disabled) return;
  const action = button.dataset.action, a = currentArticle();
  if (action === 'dismiss-overlay') { if (event.target === button) closeSheet(); return; }
  const sheets = ['settings','appearance','devices','pair','versions','translation','service','model-test','rules','backup','storage','confirm-cleanup','subscribe','article-menu','original','export-backup'];
  if (sheets.includes(action)) { showSheet(action); return; }
  if (action === 'close-sheet') { closeSheet(); return; }
  if (action === 'article' || action === 'resume') { openArticle(button.dataset.id,action === 'resume'); return; }
  if (action === 'home' || action === 'navigate' || action === 'archive-view') {
    closeSheet(); navigate(action === 'archive-view' ? 'archive' : action === 'home' ? 'today' : button.dataset.view); return;
  }
  if (action === 'back') { state.articleOpen = false; render(false); return; }
  if (action === 'category' || action === 'source') {
    closeSheet(); state.view = 'today'; state.filter = 'all'; state.query = ''; state.articleOpen = false;
    state.category = action === 'category' ? button.dataset.category : 'all'; state.source = action === 'source' ? button.dataset.source : 'all';
    state.lastAction = '筛选'+titleForView(); render(false); return;
  }
  if (action === 'filter') { state.filter = button.dataset.filter; render(); return; }
  if (action === 'refresh') { state.lastAction = '模拟刷新现有订阅，同源同条目不重复创建'; notify('订阅已刷新 · 示例文章没有重复添加。'); updateInspector(); return; }
  if (action === 'favorite') {
    a.favorite = !a.favorite; a.userFavorite = a.favorite;
    if (a.favorite && !a.archives.length && !a.cacheMissing) saveArchive(a);
    state.pending += 1; state.lastAction = a.favorite ? '手动收藏文章' : '取消收藏，归档保留';
    render(); if (state.sheet) renderSheet();
    notify(a.favorite ? '已收藏，喜欢的内容留在这里。' : '已取消收藏，保存的归档仍在。'); return;
  }
  if (action === 'read') {
    a.read = !a.read; state.pending += 1; state.lastAction = a.read ? '手动标为已读' : '手动标为未读';
    render(); if (state.sheet) closeSheet(); notify(a.read ? '已标为已读。' : '已标为未读，阅读位置保留。'); return;
  }
  if (action === 'mark-all') {
    const list = matchingArticles(); list.forEach(item => { item.read = true; }); state.pending += list.length;
    state.lastAction = '批量标记当前筛选结果为已读'; closeSheet(); render(); notify('已将当前列表的 '+list.length+' 篇文章标为已读。'); return;
  }
  if (action === 'body') {
    state.body = button.dataset.body; state.archiveId = null; state.mode = 'original';
    state.lastAction = '切换正文版本，不改变已读状态'; render(false); return;
  }
  if (action === 'extract') {
    a.extracted = true; a.cacheMissing = false; state.body = 'full'; state.archiveId = null; state.mode = 'original';
    state.lastAction = '显示预设提取全文，已有归档未改变'; render(false); notify('示例全文已展开，已有归档不会被替换。'); return;
  }
  if (action === 'save-archive') {
    if (a.cacheMissing && !versionFor(a)) { notify('本机没有当前正文，请先补取。'); return; }
    saveArchive(a); state.lastAction = '主动保存当前正文及关联结果'; render(); showSheet('versions'); notify('已保存新的归档版本，原有快照保留。'); return;
  }
  if (action === 'open-version') {
    state.archiveId = button.dataset.id; state.body = versionFor(a).kind; state.mode = 'original'; state.articleOpen = true;
    state.lastAction = '打开独立历史归档'; closeSheet(); render(false); return;
  }
  if (action === 'delete-version') { state.versionToDelete = button.dataset.id; showSheet('delete-version'); return; }
  if (action === 'confirm-delete-version') {
    a.archives = a.archives.filter(v => v.id !== state.versionToDelete);
    a.results = Object.fromEntries(Object.entries(a.results).filter(([,result]) => result.archive !== state.versionToDelete));
    if (state.archiveId === state.versionToDelete) state.archiveId = null;
    state.pending += 1; state.lastAction = '删除选定归档及附加结果，收藏和已读标记不变';
    render(); showSheet('versions'); notify('这份归档已删除，收藏和已读标记保持原样。'); return;
  }
  if (action === 'summary') { if (useGeneration('summary')) showSheet('summary'); return; }
  if (action === 'ask') { state.question = ''; state.answer = ''; showSheet('ask'); return; }
  if (action === 'translate') {
    state.language = document.getElementById('translation-language').value;
    if (state.language === 'zh') { notify('原文已经是简体中文，选择 English 体验对照。'); return; }
    if (!useGeneration('translate')) return;
    state.mode = 'bilingual'; closeSheet(); render(); notify('已打开预设英文对照，原文继续保留。'); return;
  }
  if (action === 'original-mode') { state.mode = 'original'; closeSheet(); render(); return; }
  if (action === 'send-question') {
    state.question = document.getElementById('article-question').value.trim() || '这篇文章最重要的建议是什么？';
    if (!useGeneration('question')) return;
    const rss = (versionFor(a)?.kind || state.body) === 'rss';
    state.answer = /建议|核心|重点|总结|讲|怎么|如何/.test(state.question) ? (rss ? '当前只有 RSS 摘要。它谈到：'+a.rss[0] : '根据当前文章，可以带走的是：'+a.summary.join(' ')) : '仅凭当前正文，无法确定这个问题的答案。你可以先查看文章已经提供的信息，或者换一个与正文直接相关的问题。';
    renderSheet(); return;
  }
  if (action === 'citation') {
    const paragraph = button.dataset.paragraph;
    closeSheet(); state.articleOpen = true; render();
    lastReaderGesture = 0;
    document.getElementById('paragraph-'+paragraph)?.scrollIntoView({behavior:'smooth',block:'center'}); return;
  }
  if (action === 'theme') { state.theme = button.dataset.theme; render(); renderSheet(); return; }
  if (action === 'network') {
    state.online = !state.online; state.sync = state.online ? '等待同步' : '等待连接';
    state.lastAction = '局域网连接演示切换为'+state.online; render(); renderSheet(); return;
  }
  if (action === 'sync') { runSync(); return; }
  if (action === 'revoke') { state.deviceToRevoke = button.dataset.id; showSheet('revoke'); return; }
  if (action === 'confirm-revoke') {
    const device = state.devices.find(d => d.id === state.deviceToRevoke);
    device.trusted = false; device.online = false;
    state.devices.filter(d => d.trusted && !d.online).forEach(d => { d.revocationPending = true; });
    state.sync = '等待同步'; state.pending += 1; state.lastAction = '本机撤销设备授权，离线可信设备等待接收';
    render(); showSheet('devices'); notify('授权已撤销，已提交的业务数据保留。'); return;
  }
  if (action === 'confirm-pair') {
    if (document.getElementById('pair-code').value.replace(/\s/g,'') !== '426810') { notify('演示配对码是 426 810。'); return; }
    if (!state.online) { notify('请先在设备页打开局域网演示开关。'); return; }
    const id = 'paired-demo';
    if (!state.devices.some(d => d.id === id)) state.devices.push({id,name:'新配对的设备',online:true,trusted:true});
    else Object.assign(state.devices.find(d => d.id === id),{online:true,trusted:true});
    state.lastAction = '用户明确配对一个独立设备身份'; render(); showSheet('devices'); notify('演示配对完成，可以继续同步。'); return;
  }
  if (action === 'save-service') {
    const raw = document.getElementById('service-url').value.trim();
    let url;
    try { url = new URL(raw); } catch { notify('填写包含 https:// 的完整服务地址。'); return; }
    if (!['https:','http:'].includes(url.protocol) || /\/(chat\/completions|models)\/?$/.test(url.pathname)) { notify('填写接口前缀，不要填完整生成端点。'); return; }
    const normalized = raw.replace(/\/+$/,'');
    if (normalized !== state.service.url) state.service.model = '';
    state.service.url = normalized; state.service.configured = true;
    state.service.directory = '示例目录 · 刚刚获取'; state.lastAction = '保存无密钥演示配置；模型目录不占生成额度';
    document.getElementById('service-key').value = ''; updateInspector(); renderSheet(); notify('示例目录已获取，请选择要使用的模型。'); return;
  }
  if (action === 'refresh-models') { state.service.directory = '示例目录 · 刚刚刷新'; renderSheet(); updateInspector(); notify('目录已刷新，生成调用次数不变。'); return; }
  if (action === 'confirm-model-test') {
    if (!state.service.model) { showSheet('service'); notify('请先选择或填写模型。'); return; }
    if (state.service.used >= state.service.limit) { notify('今天的演示调用额度已用尽。'); return; }
    state.service.used += 1; state.service.test = '此次示例文本调用可用 · 没有发送实际请求'; state.lastAction = '用户手动模型测试，共用生成调用额度';
    updateInspector(); showSheet('service'); return;
  }
  if (action === 'toggle-rule') {
    const rule = state.rules.find(r => r.id === button.dataset.id); rule.enabled = !rule.enabled;
    state.rulePreview = null; state.lastAction = '修改规则只影响之后的新文章'; render(); renderSheet(); return;
  }
  if (action === 'preview-rules') {
    state.rulePreview = articles.filter(item => state.rules.some(r => r.enabled && item.title.includes(r.keyword))).map(item => item.id);
    state.lastAction = '预览历史文章，尚未修改文章'; renderSheet(); updateInspector(); return;
  }
  if (action === 'enable-automation') {
    if (!state.rulePreview) { notify('先预览已有规则，再启用本机自动化。'); return; }
    state.automationPaused = false; render(); renderSheet(); notify('本机自动化已启用，只处理后续新文章。'); return;
  }
  if (action === 'run-rules') {
    let changed = 0;
    for (const id of state.rulePreview || []) {
      const item = articles.find(article => article.id === id);
      if (state.completedBatches.includes(id) || item.favorite || item.userFavorite !== null) continue;
      item.extracted = true; item.cacheMissing = false; item.favorite = true; saveArchive(item,true); state.completedBatches.push(id); changed += 1;
    }
    state.lastAction = '手动执行预览批次，保护已有用户收藏决定并防重复'; render(); renderSheet(); notify('演示处理了 '+changed+' 篇；手动决定和已有归档受到保护。'); return;
  }
  if (action === 'restore-backup') {
    for (const item of articles) {
      const original = backupArticles.find(old => old.id === item.id);
      if (!original) continue;
      if (state.restore.archives) {
        for (const v of original.archives) if (!item.archives.some(existing => existing.id === v.id)) item.archives.push(structuredClone(v));
      }
      if (state.restore.favorites) { item.favorite = original.favorite; item.userFavorite = original.favorite; }
    }
    if (state.restore.subscriptions) {
      for (const source of backupSources) if (!sources.some(existing => existing.id === source.id)) sources.push(structuredClone(source));
    }
    if (state.restore.rules) { state.rules = structuredClone(backupRules); state.automationPaused = true; state.rulePreview = null; }
    state.lastBackupAction = '从初始示例恢复所选业务数据，保留当前设备授权和阅读位置';
    state.lastAction = state.lastBackupAction; state.pending += 1;
    render(); renderSheet(); notify('所选示例数据已恢复，配对授权与更新的阅读进度保持不变。'); return;
  }
  if (action === 'confirm-export') {
    if (!document.getElementById('backup-password').value) { notify('先填写一个演示密码。'); return; }
    state.lastBackupAction = '演示加密导出步骤结束，没有创建文件'; state.lastAction = state.lastBackupAction;
    showSheet('backup'); updateInspector(); notify('导出流程预览完成；原型没有创建备份文件。'); return;
  }
  if (action === 'cleanup') {
    articles.forEach(item => { item.cacheMissing = true; item.results = {}; });
    state.cacheCleared = true; state.lastAction = '清理本机普通正文和依赖结果；长期归档与状态保留';
    render(); showSheet('storage'); notify('本机示例缓存已清理，保留归档不受影响。'); return;
  }
  if (action === 'refill') {
    if (!state.online || !state.devices.some(d => d.trusted && d.online)) { notify('等待可连接的已配对设备提供正文。'); return; }
    a.cacheMissing = false; state.lastAction = '模拟补取同一版本正文'; render(); notify('演示正文已补取，可以继续阅读。'); return;
  }
  if (action === 'add-feed') {
    const name = document.getElementById('feed-name').value.trim(), url = document.getElementById('feed-url').value.trim();
    const category = document.getElementById('feed-category').value;
    if (!name || !/^https?:\/\/\S+\.\S+/.test(url)) { notify('填写订阅名称和完整的 RSS / Atom 地址。'); return; }
    const normalized = url.replace(/\/+$/,'');
    const existing = sources.find(source => source.url === normalized || source.name === name);
    if (!existing) sources.push({id:'feed-'+Date.now(),name,short:name[0],category,color:'#657951',bg:'#e6ebdc',url:normalized});
    state.lastAction = existing ? '重复订阅已合并' : '添加内存中的示例订阅入口';
    render(); closeSheet(); notify(existing ? '已合并重复订阅，不会创建重复文章。' : '示例订阅已添加；原型不抓取内容。'); return;
  }
});
document.addEventListener('input', event => {
  const el = event.target;
  if (el.id === 'article-search') { state.query = el.value; state.lastAction = '搜索本机内容'; render(); }
  if (el.id === 'font-size') {
    state.fontSize = Number(el.value);
    document.querySelector('.article-body')?.style.setProperty('--reading-size',state.fontSize+'px');
    document.getElementById('font-preview').style.fontSize = state.fontSize+'px';
    document.getElementById('font-size-value').textContent = state.fontSize+'px'; updateInspector();
  }
  if (el.id === 'article-question') state.question = el.value;
});
document.addEventListener('change', event => {
  const el = event.target;
  if (el.id === 'translation-language') { state.language = el.value; renderSheet(); }
  if (el.id === 'service-model') { state.service.model = el.value; updateInspector(); }
  if (el.id === 'manual-model' && el.value.trim()) {
    state.service.model = el.value.trim();
    if (!state.service.models.includes(state.service.model)) state.service.models.push(state.service.model);
    renderSheet(); updateInspector();
  }
  if (el.id === 'call-limit') { state.service.limit = Math.max(1,Math.min(1000,Number(el.value)||50)); renderSheet(); updateInspector(); }
  if (el.dataset.restore) { state.restore[el.dataset.restore] = el.checked; updateInspector(); }
});
document.addEventListener('keydown', event => {
  if (event.key === 'Escape') { if (state.sheet) closeSheet(); return; }
  if (state.sheet) {
    if (event.key !== 'Tab') return;
    const focusable = [...document.querySelector('.sheet').querySelectorAll('button:not(:disabled),input,select,textarea,a[href]')];
    const first = focusable[0], last = focusable.at(-1);
    if (event.shiftKey && (document.activeElement === first || document.activeElement.classList.contains('sheet'))) { event.preventDefault(); last?.focus(); }
    else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus(); }
    return;
  }
  const editing = event.target.closest('input,textarea,select,[contenteditable]:not([contenteditable="false"])');
  if (editing) return;
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
    event.preventDefault(); document.getElementById('article-search')?.focus(); return;
  }
});
matchMedia('(prefers-color-scheme: dark)').addEventListener('change',() => { if (state.theme === 'system') render(); });
render(false);
updateInspector(true);

}
startReference().catch(error => {
  document.getElementById('app').textContent = '示例资源未能载入，请重新启动本地预览。';
  console.error(error);
});
