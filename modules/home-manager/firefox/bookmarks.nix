{...}: {
  programs.firefox.profiles.default.bookmarks = [
    {
      name = "Udemy";
      url = "https://www.udemy.com/";
      keyword = "udemy";
      tags = ["learning" "education"];
    }
  ];
}