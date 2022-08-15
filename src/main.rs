#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), reqwest::Error> {
    // Some simple CLI args requirements...
    let url = "http://127.0.0.1:3000";

    eprintln!("Fetching {:?}...", url);

    let res = reqwest::get(url).await?;

    eprintln!("Response: {:?} {}", res.version(), res.status());
    eprintln!("Headers: {:#?}\n", res.headers());

    let body = res.text().await?;
    println!("Getting: {}", body);

    let client = reqwest::Client::new();

    let res = client
        .post("http://127.0.0.1:3000/echo")
        .body("Hello server.")
        .send()
        .await?;
    let body = res.text().await?;

    println!("echo: {}", body);

    let res = client
        .post("http://127.0.0.1:3000/echo/reversed")
        .body("Hello server.")
        .send()
        .await?;
    let body = res.text().await?;

    println!("echo reversed: {}", body);

    Ok(())
}
