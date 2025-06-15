---
title: Search
subtitle: Search the Radicle Network
layout: page
variant: wide
---

<h1>Search the Radicle Network</h1>

<input type="text" placeholder="Type to filter" id="filter" onkeyup="update()" />

<style>
li {
  margin-bottom: 1.5em;
}
</style>

<ul id="search">
{% for repo in site.data.search %}
  <li>
    <a href="https://app.radicle.xyz/nodes/iris.radicle.xyz/rad:{{ repo.rid }}">{{ repo.name }}</a><br>
    {{ repo.description }}
  </li>
{% endfor %}
</ul>

<script>
const input = document.getElementById("filter")
const ul = document.getElementById("search")

function update() {
  filter(input.value)
}

function filter(needle) {
  needle = needle.toLowerCase()
  for (const li of ul.getElementsByTagName("li")) {
    li.style.display = ((li.textContent || li.innerText).toLowerCase().indexOf(needle) > -1) ? "" : "none"
  }
}

const hash = (new URLSearchParams(location.hash.substring(1))).get("s");
if (hash !== null) {
  input.value = hash
  filter(hash)
}
</script>
