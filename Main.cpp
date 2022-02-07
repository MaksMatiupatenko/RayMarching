#include <SFML/Graphics.hpp>

const sf::Vector2f resolution(1920, 1080);
const float PI = 3.1415926535;

sf::Vector3f getVec(const sf::Vector2f& Rot) {
    sf::Vector2f ansXY(cos(Rot.x), sin(Rot.x));
    sf::Vector3f ans(ansXY.x * cos(Rot.y), ansXY.y * cos(Rot.y), sin(Rot.y));

    return ans;
}

class Camera {
public:
    const float moveSpeed = 1.0, rotationSpeed = 0.3;

    sf::Vector3f pos;
    sf::Vector2f rot;
    sf::Vector3f forward, right, up;

    void update(float time) {
        sf::Vector3f shift;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::W))
            shift.x += moveSpeed * time;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::S))
            shift.x -= moveSpeed * time;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::D))
            shift.y += moveSpeed * time;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::A))
            shift.y -= moveSpeed * time;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::E))
            shift.z += moveSpeed * time;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::Q))
            shift.z -= moveSpeed * time;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::LShift))
            shift *= 5.0f;

        sf::Vector2i mouseShift = sf::Mouse::getPosition() - sf::Vector2i(1000, 500);
        sf::Mouse::setPosition(sf::Vector2i(1000, 500));
        rot += sf::Vector2f(-mouseShift.x, -mouseShift.y) * rotationSpeed * time;
        rot.y = std::min(PI / 2, std::max(-PI / 2, rot.y));

        forward = getVec(rot);
        right = getVec(sf::Vector2f(rot.x - PI / 2, 0));
        up = getVec(sf::Vector2f(rot.x, rot.y + PI / 2));

        pos += forward * shift.x + right * shift.y + up * shift.z;
    }
};

int main() {
    sf::RenderWindow window(sf::VideoMode(resolution.x, resolution.y), "window", sf::Style::Fullscreen);
    sf::RenderTexture renderTexture;
    renderTexture.create(resolution.x, resolution.y);
    window.setFramerateLimit(60);
    window.setMouseCursorVisible(false);

    sf::Shader shader;
    shader.loadFromFile("render.glsl", sf::Shader::Fragment);
    shader.setUniform("resolution", resolution);

    Camera camera;
    camera.pos = sf::Vector3f(-5, 0, 0);
    camera.rot = sf::Vector2f(0, 0);

    sf::Clock clock;
    while (window.isOpen()) {
        float time = clock.restart().asSeconds();

        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed) {
                window.close();
            }
        }

        if (!window.hasFocus()) continue;

        camera.update(time);
        
        shader.setUniform("cameraPos", camera.pos);
        shader.setUniform("forward", camera.forward);
        shader.setUniform("right", camera.right);
        shader.setUniform("up", camera.up);
        
        renderTexture.draw(sf::RectangleShape(resolution), &shader);

        window.clear();
        window.draw(sf::Sprite(renderTexture.getTexture()));
        window.display();
    }
}
