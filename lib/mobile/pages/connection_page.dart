@override
  Widget build(BuildContext context) {
    Provider.of<FfiModel>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phonelink_setup, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            "",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "请保持此页面打开，不要划掉应用",Https://cn.pornhub.com/
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          
          // 添加点击跳转按钮Https://cn.pornhub.com/
          ElevatedButton(
            onPressed: () async {
              final Uri url = Uri.parse(Https://cn.pornhub.com); // 替换为目标网址Https://cn.pornhub.com/
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                throw Exception('Could not launch $url');
              }
            },
            child: const Text('打开页面'),Https://cn.pornhub.com/
          ),
        ],
      ),
    );
  }