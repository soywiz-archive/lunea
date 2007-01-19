#include "gamelib.h"

int main() {
	Image bg, insignia, buffer;
	Font font;
	float angle = 0.0f;
	//int blurred = 0;

	GameInit();

	VideoModeSetTitle("Demo");
	VideoModeSetFPS(60);

	VideoModeSet(640, 480, true);

	bg = ImageLoadFromFile("data/images/bg.jpg");
	insignia = ImageLoadFromFile("data/images/insignia.png");
	ImageSetCXY(insignia, insignia->w / 2, insignia->h / 2);
	//insignia->cx = insignia->w / 2;
	//insignia->cy = insignia->h / 2;

	buffer = ImageCreate(insignia->w * 2, insignia->h);

	font = FontLoadFromFile("data/font.ttf", 40);

	//printf("%d, %d\n", insignia->cx, insignia->cy);

	printf("Memoria: %f MB\n", (float)((float)textureMemory / (float)1024 / (float)1024));

	while (!key[SDLK_ESCAPE]) {
		VideoModeEnable2D();

		DrawImage(bg, 0, 0);

		ImageStartDrawing(buffer);
			DrawClear();
			DrawImageEx(insignia, 0   + insignia->cx, 0 + insignia->cy, 1.0f, -angle * 1.3f);
			DrawImageEx(insignia, 100 + insignia->cx, 0 + insignia->cy, 1.0f,  angle * 0.7f);
		ImageStopDrawing();

		//VideoModeDisable2D();

		DrawImage(buffer, 20, 50);

		DrawImageEx(insignia, 20       + insignia->cx, 250 + insignia->cy, 1.0f, -angle * 1.3f);
		DrawImageEx(insignia, 20 + 100 + insignia->cx, 250 + insignia->cy, 1.0f,  angle * 0.7f);

		ColorSet(1.0f, 1.0f, 1.0f, 1.0f);
		DrawFont(font, 311, 130, "Sobre buffer");
		DrawFont(font, 311, 330, "Sobre pantalla");

		ColorSet(0.0f, 0.0f, 0.0f, 1.0f);
		DrawFont(font, 310, 130, "Sobre buffer");
		DrawFont(font, 310, 330, "Sobre pantalla");

		DrawImageEx(insignia, 640, 0, 1.2f, angle);
		VideoModeDisable2D();
		VideoModeFrame();
		angle = angle + 0.01;
	}

	/*
	ImageFree(bg);
	ImageFree(insignia);
	ImageFree(buffer);
	FontFree(font);
	GameQuit();
	*/

	return 0;
}
