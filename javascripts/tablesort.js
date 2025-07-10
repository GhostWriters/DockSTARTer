document$.subscribe(() => {
  var tables = document.querySelectorAll("article table:not([class])");
  tables.forEach((table) => {
    new Tablesort(table);
  });
});
