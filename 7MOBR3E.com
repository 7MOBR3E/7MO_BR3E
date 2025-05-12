<!DOCTYPE html><html lang="ar">
<head>
  <meta charset="UTF-8">
  <title>موقع محمد برعي</title>
  <style>
    body {
      background-color: black;
      color: white;
      font-family: Arial, sans-serif;
      text-align: center;
      margin: 0;
      padding: 0;
    }
    input[type="password"], input[type="url"], input[type="text"], textarea {
      padding: 15px;
      font-size: 20px;
      width: 300px;
      border: none;
      border-radius: 10px;
      margin: 10px 0;
    }
    textarea {
      height: 100px;
    }
    button {
      padding: 10px 25px;
      margin: 10px;
      font-size: 18px;
      border-radius: 10px;
      border: none;
      cursor: pointer;
    }
    #main {
      display: none;
      padding: 20px;
    }
    .content-item {
      background-color: #222;
      padding: 10px;
      border-radius: 10px;
      margin: 10px auto;
      max-width: 90%;
      position: relative;
    }
    .delete-btn, .edit-btn {
      position: absolute;
      top: 5px;
      background-color: red;
      color: white;
      border: none;
      padding: 5px 10px;
      border-radius: 5px;
      cursor: pointer;
    }
    .edit-btn {
      right: 60px;
      background-color: orange;
    }
    .delete-btn {
      right: 5px;
    }
    .back-btn {
      position: absolute;
      left: 10px;
      top: 10px;
      font-size: 18px;
    }
    a.download-link {
      color: lightgreen;
      display: block;
      margin-top: 10px;
    }
    #searchInput {
      margin: 20px;
      padding: 10px;
      width: 80%;
      font-size: 18px;
      border-radius: 10px;
      border: none;
    }
  </style>
</head>
<body><div id="login">
  <h1>مرحباً بك في موقعنا</h1>
  <input type="password" id="passwordInput" placeholder="أدخل كلمة المرور">
  <br>
  <button onclick="login()">دخول</button>
  <button onclick="enterAsGuest()">ضيف</button>
</div><div id="main">
  <button class="back-btn" onclick="goBack()">رجوع</button>
  <h1>محمد برعي</h1>
  <h2>روابط أو ملفات أو نصوص لأي شيء</h2>  <div class="content-item">
    <p>سيرفرنا ديسكورد 👇</p>
    <a href="https://discord.gg/uj6xQS4y" target="_blank" style="color:lightblue;">https://discord.gg/uj6xQS4y</a>
  </div>  <input type="text" id="searchInput" placeholder="ابحث عن أي شيء" oninput="searchContent()">  <div id="addSection" class="add-section" style="display:none;">
    <input type="text" id="descriptionInput" placeholder="وصف المحتوى">
    <br>
    <input type="url" id="linkInput" placeholder="رابط">
    <button onclick="addLink()">إضافة رابط</button><br><br><input type="file" id="fileInput" onchange="addFile()"><br><br>

<textarea id="textInput" placeholder="اكتب نص هنا..."></textarea><br>
<button onclick="addText()">إضافة نص</button>

  </div>  <div id="contentArea"></div>
</div><script>
  const PASSWORD = "oopfoxmrso";
  let isOwner = false;

  window.onload = function () {
    const session = sessionStorage.getItem("userType");
    if (session === "owner") {
      isOwner = true;
      showMain();
    } else if (session === "guest") {
      isOwner = false;
      showMain();
    }
  };

  function login() {
    const input = document.getElementById("passwordInput").value;
    if (input === PASSWORD) {
      isOwner = true;
      sessionStorage.setItem("userType", "owner");
      showMain();
    } else {
      alert("كلمة المرور غير صحيحة");
    }
  }

  function enterAsGuest() {
    isOwner = false;
    sessionStorage.setItem("userType", "guest");
    showMain();
  }

  function goBack() {
    sessionStorage.removeItem("userType");
    document.getElementById("main").style.display = "none";
    document.getElementById("login").style.display = "block";
    document.getElementById("contentArea").innerHTML = "";
    document.getElementById("passwordInput").value = "";
  }

  function showMain() {
    document.getElementById("login").style.display = "none";
    document.getElementById("main").style.display = "block";
    document.getElementById("addSection").style.display = isOwner ? "block" : "none";
    loadContent();
  }

  function addLink() {
    if (!isOwner) return;
    const link = document.getElementById("linkInput").value;
    const desc = document.getElementById("descriptionInput").value;
    if (link) {
      const item = { type: "link", value: link, desc };
      saveItem(item);
      renderItem(item);
      document.getElementById("linkInput").value = "";
      document.getElementById("descriptionInput").value = "";
    }
  }

  function addFile() {
    if (!isOwner) return;
    const file = document.getElementById("fileInput").files[0];
    const desc = document.getElementById("descriptionInput").value;
    const reader = new FileReader();
    reader.onload = function(e) {
      const item = {
        type: file.type.startsWith("video") ? "video" : "file",
        value: e.target.result,
        name: file.name,
        desc
      };
      saveItem(item);
      renderItem(item);
    };
    reader.readAsDataURL(file);
  }

  function addText() {
    if (!isOwner) return;
    const text = document.getElementById("textInput").value;
    const desc = document.getElementById("descriptionInput").value;
    if (text.trim() !== "") {
      const item = { type: "text", value: text, desc };
      saveItem(item);
      renderItem(item);
      document.getElementById("textInput").value = "";
      document.getElementById("descriptionInput").value = "";
    }
  }

  function saveItem(item) {
    const items = JSON.parse(localStorage.getItem("siteContent") || "[]");
    items.push(item);
    localStorage.setItem("siteContent", JSON.stringify(items));
  }

  function loadContent() {
    const items = JSON.parse(localStorage.getItem("siteContent") || "[]");
    items.forEach((item, index) => renderItem(item, index));
  }

  function renderItem(item, index = null) {
    const container = document.getElementById("contentArea");
    const div = document.createElement("div");
    div.className = "content-item";

    if (item.desc) {
      const d = document.createElement("p");
      d.innerText = item.desc;
      div.appendChild(d);
    }

    if (item.type === "link") {
      const a = document.createElement("a");
      a.href = item.value;
      a.innerText = item.value;
      a.target = "_blank";
      a.style.color = "lightblue";
      div.appendChild(a);
    } else if (item.type === "file") {
      if (item.value.startsWith("data:image")) {
        const img = document.createElement("img");
        img.src = item.value;
        img.style.maxWidth = "100%";
        div.appendChild(img);
      }
      const a = document.createElement("a");
      a.href = item.value;
      a.download = item.name;
      a.className = "download-link";
      a.innerText = "تحميل الملف";
      div.appendChild(a);
    } else if (item.type === "video") {
      const video = document.createElement("video");
      video.controls = true;
      video.src = item.value;
      video.style.maxWidth = "100%";
      div.appendChild(video);
    } else if (item.type === "text") {
      const p = document.createElement("p");
      p.innerText = item.value;
      p.style.whiteSpace = "pre-wrap";
      div.appendChild(p);
    }

    container.appendChild(div);
  }

  function searchContent() {
    const query = document.getElementById("searchInput").value.toLowerCase();
    const items = JSON.parse(localStorage.getItem("siteContent") || "[]");
    document.getElementById("contentArea").innerHTML = "";
    items.forEach((item, index) => {
      const content = (item.value + (item.desc || "")).toLowerCase();
      if (content.includes(query)) renderItem(item, index);
    });
  }
</script></body>
</html>
