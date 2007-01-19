typedef struct _Image _Image;
typedef struct _Image *Image;

extern int textureMemory;

struct _Image {
	Image father;

	GLuint gltex;
	//GLuint dlist;

	int x, y, w, h;

	// Centro de la imagen
	int cx, cy;

	int rw, rh;

	GLuint callList;

	struct { float x, y; } texp[4];
};

Image ImageCreate(int w, int h);
Image ImageCreateFromSubImage(Image vpi, int x, int y, int w, int h);
Image ImageLoadFromStreamEx(Stream s, int freesrc);
Image ImageLoadFromStream(Stream s);
Image ImageLoadFromMemory(void *ptr, int length);
Image ImageLoadFromFile(char *filename);
#define ImageLoad ImageLoadFromFile
void ImageFree(Image i);

Image ImageDuplicate(Image i);

void ImageSetCXY(Image i, int cx, int cy);

void DrawImageEx(Image i, int x, int y, float alpha, float size);
void DrawImage(Image i, int x, int y);

