#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), reqwest::Error> {
    // Some simple CLI args requirements...
    let url = "http://eu.httpbin.org/get?msg=WasmEdge";

    eprintln!("Fetching {:?}...", url);

    let res = reqwest::get(url).await?;

    eprintln!("Response: {:?} {}", res.version(), res.status());
    eprintln!("Headers: {:#?}\n", res.headers());

    let body = res.text().await?;
    println!("GET: {}", body);

    let client = reqwest::Client::new();

    let res = client
        .post("http://eu.httpbin.org/post")
        .body("msg=WasmEdge")
        .send()
        .await?;
    let body = res.text().await?;

    println!("POST: {}", body);

    let res = client
        .put("http://eu.httpbin.org/put")
        .body("msg=WasmEdge")
        .send()
        .await?;
    let body = res.text().await?;

    println!("PUT: {}", body);

    Ok(())
}
