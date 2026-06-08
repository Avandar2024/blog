(function () {
  const form = document.querySelector(".search-form");
  const input = document.querySelector("#search-query");
  const status = document.querySelector("#search-status");
  const results = document.querySelector("#search-results");

  if (!form || !input || !status || !results) return;

  const params = new URLSearchParams(window.location.search);
  const initialQuery = params.get("q") || "";
  let documents = [];

  try {
    if (!window.searchIndex) {
      throw new Error("Missing local search assets.");
    }

    documents = Object.values(window.searchIndex.documentStore.docs || {});
  } catch (error) {
    status.textContent = "Search index is unavailable.";
    console.error(error);
    return;
  }

  if (initialQuery) {
    input.value = initialQuery;
    search(initialQuery);
  }

  form.addEventListener("submit", function (event) {
    event.preventDefault();
    const query = input.value.trim();
    const nextUrl = new URL(window.location.href);

    if (query) {
      nextUrl.searchParams.set("q", query);
    } else {
      nextUrl.searchParams.delete("q");
    }

    window.history.replaceState({}, "", nextUrl);
    search(query);
  });

  function search(query) {
    results.replaceChildren();

    if (!query) {
      status.textContent = "Enter a query to search posts and pages.";
      return;
    }

    const hits = documents
      .map((doc) => scoreDocument(doc, query))
      .filter((hit) => hit.score > 0)
      .sort((a, b) => b.score - a.score);

    renderResults(hits, query);
  }

  function scoreDocument(doc, query) {
    const normalizedQuery = normalize(query);
    const queryTerms = tokenize(normalizedQuery);
    const title = normalize(doc.title || "");
    const body = normalize(doc.body || "");
    let score = 0;

    if (title.includes(normalizedQuery)) score += 30;
    if (body.includes(normalizedQuery)) score += 10;

    for (const term of queryTerms) {
      if (term.length === 0) continue;
      score += countOccurrences(title, term) * 8;
      score += countOccurrences(body, term) * 2;
    }

    return { doc, score };
  }

  function tokenize(value) {
    const terms = value.match(/[\p{Script=Han}]+|[a-z0-9_+-]+/gu) || [];
    const expanded = [];

    for (const term of terms) {
      expanded.push(term);
      if (/[\p{Script=Han}]/u.test(term) && term.length > 1) {
        for (const char of term) expanded.push(char);
      }
    }

    return expanded;
  }

  function normalize(value) {
    return String(value).toLocaleLowerCase();
  }

  function countOccurrences(value, term) {
    let count = 0;
    let index = value.indexOf(term);

    while (index !== -1) {
      count += 1;
      index = value.indexOf(term, index + term.length);
    }

    return count;
  }

  function renderResults(hits, query) {
    if (hits.length === 0) {
      status.textContent = "No results for \"" + query + "\".";
      return;
    }

    status.textContent = hits.length + " result" + (hits.length === 1 ? "" : "s") + " for \"" + query + "\".";

    for (const hit of hits.slice(0, 12)) {
      const doc = hit.doc || {};
      const item = document.createElement("li");
      const link = document.createElement("a");
      const excerpt = document.createElement("p");

      link.href = doc.id || hit.ref;
      link.textContent = doc.title || doc.id || hit.ref;
      excerpt.textContent = makeExcerpt(doc.body || "");

      item.append(link, excerpt);
      results.append(item);
    }
  }

  function makeExcerpt(body) {
    const normalized = body.replace(/\s+/g, " ").trim();
    if (normalized.length <= 180) return normalized;
    return normalized.slice(0, 180).trimEnd() + "...";
  }
})();
