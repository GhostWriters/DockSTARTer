var script = document.createElement("script");
script.src = "https://www.googletagmanager.com/gtag/js?id=G-QVNLHE95FS";
document.head.appendChild(script);

app.location$.subscribe(function (url) {
  window.dataLayer = window.dataLayer || [];
  function gtag() {
    dataLayer.push(arguments);
  }
  gtag("js", new Date());

  gtag("config", "G-QVNLHE95FS");
});
