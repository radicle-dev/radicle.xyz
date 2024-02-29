const rootElement = document.documentElement;
const themeToggleBtn = document.getElementById("toggle-theme");
const storedTheme = localStorage.getItem("theme");
const defaultTheme = window.matchMedia
  && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";

setTheme(storedTheme || defaultTheme);

if (themeToggleBtn) {
  themeToggleBtn.addEventListener("click", () => {
    const currentTheme = rootElement.dataset.theme;

    if (currentTheme === "dark") {
      setTheme("light");
    } else {
      setTheme("dark");
    }
  });
}

function setTheme(theme) {
  rootElement.dataset.theme = theme;
  localStorage.setItem("theme", theme);
}
