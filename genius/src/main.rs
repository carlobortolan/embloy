use actix_web::{App, HttpServer, web, Responder};
use actix_web::web::Data;
use std::sync::Mutex;
struct AppState {
    counter: Mutex<i32>,
}
// Handler to get the current counter value
async fn get_counter(data: Data<AppState>) -> impl Responder {
    let counter = data.counter.lock().unwrap();
    format!("Counter: {}", *counter)
}

// Handler to increment the counter
async fn increment_counter(data: Data<AppState>) -> impl Responder {
    let mut counter = data.counter.lock().unwrap();
    *counter += 1;
    format!("Counter incremented to: {}", *counter)
}
#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize shared state
    let shared_state = Data::new(AppState {
        counter: Mutex::new(0),
    });

    // Start the HTTP server
    HttpServer::new(move || {
        App::new()
            .app_data(shared_state.clone()) // Add shared state to the app
            .route("/counter", web::get().to(get_counter)) // Route to get counter
            .route("/increment", web::post().to(increment_counter)) // Route to increment counter
    })
    .bind("127.0.0.1:8080")? // Bind server to localhost on port 8080
    .run()
    .await
}